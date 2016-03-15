%%%-------------------------------------------------------------------
%%% @author chathuri
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Mar 2016 12:40
%%%-------------------------------------------------------------------
-module(riak_kv_ord_service_ets).
-author("chathuri").

-include_lib("stdlib/include/ms_transform.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-include("riak_kv_causal_service.hrl").
-define(Label_Table_Name, labels).


%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([add_label/2,test/0,partition_heartbeat/2,print_status/0]).

-define(SERVER, ?MODULE).

-record(state, {heartbeats,reg_name,added,deleted}).

test()->
    Status=net_kernel:connect_node('riak@127.0.0.1'), %this is the node where we run global server
    global:sync(),
      io:format("calling test ~p ~n",[Status]),
    case catch gen_server:call({global,riak_kv_ord_service_ets},{test}) of
        {'EXIT', ErrorExit} -> io:fwrite("ErrorExit ~p~n",[ErrorExit]),lager:info("error is ~p ~n",[ErrorExit]);
            {_, _}  ->lager:info("another error occured  ~n");
            ok->lager:info("this is working")
    end.


add_label(Label,Client_Id)->
    %lager:info("label is ready to add to the ordeing service  ~p",[Label]),
    gen_server:cast({global,riak_kv_ord_service_ets},{add_label,Label,Client_Id}).

partition_heartbeat(Partition,Clock)->
    gen_server:cast({global,riak_kv_ord_service_ets},{partition_heartbeat,Clock,Partition}).

%to print status when we need
print_status()->
    gen_server:call({global,riak_kv_ord_service_ets}, {trigger}).


start_link() ->
    gen_server:start_link({global,riak_kv_ord_service_ets}, ?MODULE, [riak_kv_ord_service_ets], []).

init([ServerName]) ->
    lager:info("ordering service started"),
    ClientCount=app_helper:get_env(riak_kv, clients),
    lager:info("client_count is ~p ~n",[ClientCount]),
    Dict1=get_clients(ClientCount,dict:new()),
    lager:info("dictionary size is ~p ~n",[dict:size(Dict1)]),
    erlang:send_after(30000, self(), print_stats),
    ets:new(?Label_Table_Name, [duplicate_bag, named_table]),
    {ok, #state{heartbeats = Dict1, reg_name = ServerName,added = 0,deleted = 0}}.



handle_call({trigger},_From, State=#state{added = Added,deleted = Deleted}) ->

    lager:info("added count is ~p deleted count is ~p ~n",[Added,Deleted]),
    {reply,ok,State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.


handle_cast({add_label,Label,Partition},State=#state{heartbeats = Heartbeats,added = Added,deleted = Deleted})->
    %lager:info("received label from ~p ~n",[Partition]),
    Label_Timestamp=Label#label.timestamp,
    ets:insert(?Label_Table_Name,{Label_Timestamp,Label}),
    Heartbeats1= dict:store(Partition,Label_Timestamp,Heartbeats),
    %todo: test functionality of only send heartbeats when no label has sent fix @ vnode
    Deleted1=deliver_possible_labels(Heartbeats1,Deleted),

    State1=State#state{heartbeats = Heartbeats1,added = Added+1,deleted = Deleted1},

    %lager:info("Label ~p and heartbeat is ~p",[orddict:fetch(Label_Timestamp,Labels1),dict:fetch(Partition,Heartbeats1)]),
    {noreply,State1};


handle_cast(_Request, State) ->
    lager:error("received an unexpected  message ~n"),
    {noreply, State}.

handle_info(print_stats, State=#state{added = Added,deleted = Deleted}) ->
    {_,{Hour,Min,Sec}} = erlang:localtime(),
    case (State#state.deleted>0) of
        true->
            %add_line_to_file(Added,Deleted,Max_Delay,FileName);
            lager:info("timestamp ~p: ~p: ~p: added ~p deleted ~p ~n",[Hour,Min,Sec,Added,Deleted]);
        false->%add_line_to_file(Added,0,Max_Delay,FileName)
            lager:info("timestamp ~p: ~p: ~p: added ~p deleted ~p  ~n",[Hour,Min,Sec,Added,0])
    end,
    erlang:send_after(30000, self(), print_stats),
    {noreply, State};


handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

get_clients(0,Dict)->Dict;

get_clients(N, Dict) -> if
                       N>0 ->Dict1=dict:store(N, N, Dict) ,get_clients(N-1,Dict1);
                       true -> get_clients(0,Dict)
                   end.

deliver_possible_labels(Heartbeats,Deleted)->
    Min_Stable_Timestamp=get_stable_timestamp(Heartbeats),
    deliver_labels(Min_Stable_Timestamp,Deleted).

%get_max_delay(Labels,Current_Max_Delay)->

   % case(orddict:size(Labels)>0) of
    %    true-> Earliest_Ts=get_earliest_label_timestamp(Labels,Current_Max_Delay),
     %       New_Max_Delay=riak_kv_util:get_timestamp()-Earliest_Ts,

      %      case(New_Max_Delay>Current_Max_Delay) of
       %         true->New_Max_Delay;
        %        false->Current_Max_Delay
         %   end;
        %false->Current_Max_Delay
    %end.

get_stable_timestamp(Heartbeats)->
    HB_List=dict:to_list(Heartbeats),
    [First|Rest]=HB_List,
    {_Partition,Clock}=First,
    lists:foldl(fun({_Key,Val},Min)->
        %lager:info("key is ~p value is ~p ~n",[Key,Val]),
        if
            Val<Min-> Val;
            true -> Min
        end end,Clock,Rest).

deliver_labels(Min_Clock,Deleted)->
    Begin_Table_Size=ets:info(?Label_Table_Name,size),
    ets:select_delete(?Label_Table_Name,  ets:fun2ms(fun({X,_Y}) when (X =< Min_Clock)-> true end)),
    After_Table_Size=ets:info(?Label_Table_Name,size),
    Deleted+(Begin_Table_Size-After_Table_Size).
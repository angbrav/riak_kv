%%%-------------------------------------------------------------------
%%% @author chathuri
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Mar 2016 12:40
%%%-------------------------------------------------------------------
-module(riak_kv_optimised_sequencer).
-author("chathuri").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([forward_put_to_sequencer/5,test/0]).

-define(SERVER, ?MODULE).

-record(state, {count, sequence_id}).

test()->
    Status=net_kernel:connect_node('riak@127.0.0.1'), %this is the node where we run global server
    global:sync(),
      io:format("calling test ~p ~n",[Status]),
    case catch gen_server:call({global,riak_kv_optimised_sequencer},{test}) of
        {'EXIT', ErrorExit} -> io:fwrite("ErrorExit ~p~n",[ErrorExit]),lager:info("error is ~p ~n",[ErrorExit]);
            {_, _}  ->lager:info("another error occured  ~n");
            ok->lager:info("this is working")
    end.


forward_put_to_sequencer(RObj,Options, [Node, ClientId],ReqId,Sender)->
    %net_kernel:connect_node('riak@127.0.0.1'), %this is the node where we run global server
   % global:sync(),
   % gen_server:call({global,riak_kv_optimised_sequencer}, {put,RObj, Options,[Node, ClientId],ReqId,Sender}).
    gen_server:cast({global,riak_kv_optimised_sequencer}, {put,RObj, Options,[Node, ClientId],ReqId,Sender}).

start_link() ->
    gen_server:start_link({global,riak_kv_optimised_sequencer}, ?MODULE, [riak_kv_optimised_sequencer], []).

init([_ServerName]) ->
    lager:info("optimized sequencer strted ~n"),
    erlang:send_after(30000, self(), print_stats),
    {ok, #state{count = 0,sequence_id = 0}}.

handle_call({test}, _From,State) ->
    lager:info("request received by server ~n"),
    {reply,ok, State};

handle_call(Request, _From, State) ->
    lager:info("received msg is ~p ~n",[Request]),
    %lager:info("received msg is ~p ~n",[Request]),
    {reply, ok, State}.

handle_cast({put,RObj, _Options,[_Node, _ClientId],ReqId,Sender},State=#state{sequence_id = SequenceId,count = Count})->
    BKey = {riak_object:bucket(RObj), riak_object:key(RObj)},
    BucketProps = riak_core_bucket:get_bucket(riak_object:bucket(RObj)),
    DocIdx = riak_core_util:chash_key(BKey, BucketProps),
    Preflist = riak_core_apl:get_primary_apl(DocIdx, 1, riak_kv),
    [{_IndexNode, _Type}] = Preflist,
    Sender!{ReqId,ok},
    {noreply,State#state{sequence_id = SequenceId+1,count = Count+1}};

handle_cast({test}, State) ->
    lager:info("put request received by server ~n"),
    {noreply, State}.

handle_info(print_stats, State=#state{count=Count}) ->
    {_,{Hour,Min,Sec}} = erlang:localtime(),
    lager:info("timestamp ~p: ~p: ~p: added ~n",[Hour,Min,Sec,Count]),
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

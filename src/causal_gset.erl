-module(causal_gset).

-export([add/2, value/1, new/0]).

add([], CRDT) ->
    CRDT;

add([Element|Rest], CRDT0) ->
    case lists:member(Element, CRDT0) of
        false ->
            CRDT = CRDT0 ++ [Element],
            add(Rest, CRDT);
        true ->
            add(Rest, CRDT0)
    end.

new() ->
    [].

value(CRDT) ->
    CRDT.

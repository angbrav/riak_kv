-module(causal_pncounter).

-export([increment/2, decrement/2, value/1, new/0]).

increment([], CRDT) ->
    CRDT + 1;

increment([Incs], CRDT) ->
    CRDT + Incs.

decrement([], CRDT) ->
    CRDT - 1;

decrement([Decs], CRDT) ->
    CRDT - Decs.

new() ->
    0.

value(CRDT) ->
    CRDT.

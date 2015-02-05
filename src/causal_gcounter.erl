-module(causal_gcounter).

-export([increment/2, value/1, new/0]).

increment([], CRDT) ->
    CRDT + 1;

increment([Incs], CRDT) ->
    CRDT + Incs.

new() ->
    0.

value(CRDT) ->
    CRDT.

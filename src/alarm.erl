-module(alarm).

-export([loop/4]).

loop(Frequency, Module, Function, Args) ->
    timer:sleep(Frequency),
    Module:Function(Args),
    loop(Frequency, Module, Function, Args).

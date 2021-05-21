%% @author edmondfrank
%% @doc @todo Add description to tut

-module(erlangtut).


-import(string, [len/1, concat/2, chr/2, substr/3, str/2,
                to_lower/1, to_upper/1]).

-export([hello_world/0, add/2, add/3]).

hello_world() ->
    io:fwrite("Hello World\n").

add(A, B) ->
    hello_world(),
    A + B.

add(A, B, C) ->
    hello_world(),
    A + B + C.
%% ==================================================
%% API Functions
%% ==================================================

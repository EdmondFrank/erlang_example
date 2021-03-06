-module(tr_app).

-behaviour(application). % 行为模式声明

-export([start/2, stop/1]).

start(_Type, _StartArgs) ->
    case tr_sup:start_link() of % 启动根监督者
        {ok, Pid} ->
            {ok, Pid};
        Other ->
            {error, Other}
    end.

stop(_State) ->
    ok.

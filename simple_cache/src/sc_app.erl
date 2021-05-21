-module(sc_app).

-behaviour(application).  % 行为模式声明

-export([start/2, stop/1]).   %导出的行为模式回调函数

start(_StartType, _StartArgs) ->
    sc_store:init(),               %存储初始化
    case sc_sup:start_link() of    %启动根监督者
        {ok, Pid} ->
            {ok, Pid};
        Other ->
            {error, Other}
    end.

stop(_State) ->
    ok.

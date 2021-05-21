%%% ----------------------------------------------
%%% @author edmomdfrank@yahoo.com
%%% @copyright 2008-2010 EdmondFrank
%%% @doc RPC over TCP server
%%% @end
%%% ----------------------------------------------
-module(tr_server).
-include_lib("eunit/include/eunit.hrl").
-behaviour(gen_server).

%% API
-export([
         start_link/1,
         start_link/0,
         get_count/0,
         stop/0
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).                          % 将SERVER设置为模块名
-define(DEFAULT_PORT, 1055).                       % 定义默认端口


-record(state, {port, lsock, request_count = 0}).  % 用于保存进程状态

%%% ===========================================
%%% EUnit
%%% ===========================================
start_test() ->
    {ok, _} = tr_server:start_link(1055).

%%% ============================================
%%% API
%%% ============================================


%% ----------------------------------------------
%% @doc Starts the server.
%% @spec start_link(Port::integer()) -> {ok, Pid}
%% where
%%  Pid = pid()
%% @end
%% ----------------------------------------------
start_link(Port) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [Port], []).

%% @spec start_link() -> {ok, Pid}
%% @doc Calls `start_link(Port)` using the default port.
start_link() ->
    start_link(?DEFAULT_PORT).

%% ---------------------------------------------
%% @doc Fetches the number of requests made to this server.
%% @spec get_count() -> {ok, Count}
%% where
%%  Count = integer()
%% @end
%% ---------------------------------------------
get_count() ->
    gen_server:call(?SERVER, get_count).

%% ----------------------------------------------
%% @doc Stops the server.
%% @spec stop() -> ok.
%% @end
%% ----------------------------------------------
stop() ->
    gen_server:cast(?SERVER, stop).


%%% ==============================================
%%% gen_server callbacks
%%% ==============================================
init([Port]) ->
    {ok, LSock} = gen_tcp:listen(Port, [{active, true}]),
    {ok, #state{port = Port, lsock = LSock}, 0}.

handle_call(get_count, _From, State) ->
    {reply, {ok, State#state.request_count}, State}.

handle_cast(stop, State) ->
    {stop, normal, State}.

handle_info({tcp, Socket, RawData}, State) ->
    do_rpc(Socket, RawData),
    RequestCount = State#state.request_count,
    {noreply, State#state{request_count = RequestCount + 1}};

handle_info(timeout, #state{lsock = LSock} = State) ->
    {ok, _Sock} = gen_tcp:accept(LSock),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%% ===============================================
%%% Internal functions
%%% ===============================================
do_rpc(Socket, RawData) ->
    try
        {M, F, A} = split_out_mfa(RawData),
        Result = apply(M, F, A),  % 执行请求中的调用
        gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Result]))
    catch
        _Class:Err ->
            gen_tcp:send(Socket, io_lib:fwrite("~p~n", [Err]))
    end.

split_out_mfa(RawData) ->
    MFA = re:replace(RawData, "\r\n$", "", [{return, list}]), % 丢弃回车换行符
    {match, [M, F, A]} =
        re:run(MFA, % 解析请求串
               "(.*):(.*)\s*\\((.*)\s*\\)\s*.\s*$",
               [{capture, [1,2,3], list}, ungreedy]),
    {list_to_atom(M), list_to_atom(F), args_to_terms(A)}.

args_to_terms(RawArgs) ->
    {ok, Toks, _Line} = erl_scan:string("[" ++ RawArgs ++ "]. ", 1),
    {ok, Args} = erl_parse:parse_term(Toks),
    Args.

defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @core_lua_path Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
  @core_lua File.read!(@core_lua_path)
  @content_path Path.join([:code.priv_dir(:bleep), "content", "change_update.lua"])

  @impl true
  def mount(_params, _session, socket) do
    BleepWeb.Endpoint.subscribe("room:bleep-audio")
    kalman = Kalman.new(q: 0.005, r: 1, x: 0.05)

    {:ok,
     socket
     |> assign(:kalman, kalman)
     |> assign(:bleep_latency, 50.0)
     |> assign(:data, data_from_lua(@content_path))}
  end

  def data_from_lua(path) do
    content_lua = File.read!(path)
    lua = :luerl_sandbox.init()

    lua =
      :luerl.set_table(
        [<<"uuid">>],
        fn _args, state ->
          {[UUID.uuid4()], state}
        end,
        lua
      )

    {_, lua} =
      :luerl.do(
        "
      function markdown(s)
        return {
          kind = \"markdown\",
          content = s,
          uuid = uuid()
        }
      end

      function editor(s)
        return {
          kind = \"editor\",
          content = s,
          lang = \"lua\",
          uuid = uuid()
        }
      end
      ",
        lua
      )

    {:ok, result, _new_state} = :luerl_new.do_dec(content_lua, lua)
    result = lua_table_array_to_list(hd(result))

    Enum.map(result, fn frag_info ->
      frag_info = lua_table_to_map(frag_info)
      frag_info = Map.put(frag_info, :uuid, UUID.uuid4())
      frag_info
    end)
  end

  def lua_table_array_to_list(table) do
    map = lua_table_to_map(table)
    array_map_to_list(map)
  end

  def array_map_to_list(map, index \\ 1) do
    case Map.has_key?(map, index) do
      true ->
        [Map.get(map, index) | array_map_to_list(map, index + 1)]

      false ->
        []
    end
  end

  def render_frag(%{kind: "video"} = assigns) do
    ~H"""
    <video class="align-middle rounded-xl" width="640" height="480" controls>
      <source src={@src} type="video/quicktime" /> Your browser does not support the video tag.
    </video>
    """
  end

  def render_frag(%{kind: "markdown"} = assigns) do
    md = Earmark.as_html!(String.trim(assigns[:content]))
    assigns = assign(assigns, :markdown, md)

    ~H"""
    <div class="mt-4 text-sm px-7 text-zinc-200 bg-zinc-800 dark:bg-zinc-900">
      <%= Phoenix.HTML.raw(@markdown) %>
    </div>
    """
  end

  def render_frag(%{kind: "mermaid"} = assigns) do
    ~H"""
    <div class="p-8 bg-blue-100 border border-zinc-600 rounded-xl dark:bg-slate-100">
      <div class="mermaid" phx-update="ignore" id={@uuid}>
        <%= @content %>
      </div>
    </div>
    """
  end

  def render_frag(%{kind: "editor"} = assigns) do
    assigns = assign(assigns, :run_button_id, "run-button-#{assigns[:uuid]}")
    assigns = assign(assigns, :cue_button_id, "cue-button-#{assigns[:uuid]}")
    assigns = assign(assigns, :monaco_path, "#{assigns[:uuid]}.lua")
    assigns = assign(assigns, :monaco_id, "monaco-#{assigns[:uuid]}")
    assigns = assign(assigns, :result_id, "result-#{assigns[:uuid]}")

    ~H"""
    <div class="h-full p-7">
      <div
        id={@uuid}
        class=""
        phx-hook="BleepEditor"
        phx-update="ignore"
        data-language="lua"
        data-content={@content}
        data-monaco-id={@monaco_id}
        data-path={@monaco_path}
        data-result-id={@result_id}
        data-run-button-id={@run_button_id}
        data-cue-button-id={@cue_button_id}
      >
        <button
          class="px-2 py-1 font-bold text-white bg-orange-600 rounded hover:bg-orange-800"
          id={@run_button_id}
        >
          Run
        </button>
        <button
          class="px-2 py-1 font-bold text-white bg-orange-600 rounded hover:bg-orange-800"
          id={@cue_button_id}
        >
          Cue
        </button>
        <div class="h-full pt-3 pb-3 overflow-scroll bg-black border border-orange-600 rounded-sm">
          <div class="h-full" id={@monaco_id} monaco-code-editor></div>
        </div>
      </div>
      <div class="font-mono text-sm border border-zinc-600 text-zinc-200 bg-zinc-500 bottom-9 dark:bg-zinc-800">
        <div phx-update="ignore" id={@result_id}></div>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-zinc-100" id="bleep-time" phx-hook="BleepTime">
      <p>
        Latency: <%= Float.round(@bleep_latency, 2) %> ms
      </p>
    </div>

    <%= for frag <- @data do %>
      <div class="">
        <.render_frag {frag} />
      </div>
    <% end %>
    """
  end

  def lua_time(lua) do
    {[global_time_s | _rest], lua} = :luerl.do(<<"return bleep_global_time">>, lua)
    {[start_time_s | _rest], _lua} = :luerl.do(<<"return bleep_start_time">>, lua)
    global_time_s + start_time_s
  end

  def bleep_core_start_fx(lua, [uuid, fx_id]) do
    bleep_core_start_fx(lua, [uuid, fx_id, []])
  end

  def bleep_core_start_fx(lua, [uuid, fx_id, opts_table]) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)

    tag = "*"

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time_s, tag, {:core_start_fx, uuid, fx_id, output_id, opts}}
    )
  end

  def bleep_core_stop_fx(lua, [uuid]) do
    time_s = lua_time(lua)
    opts = %{}
    tag = "*"

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time_s, tag, {:core_stop_fx, uuid, opts}}
    )
  end

  def sample(lua, [sample_name]) when is_binary(sample_name) do
    sample(lua, [sample_name, []])
  end

  def sample(lua, [sample_name, opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    tag = "*"

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time_s, tag, {:sample, sample_name, output_id, opts}}
    )
  end

  def play(lua, [note]) when is_integer(note) or is_float(note) do
    play(lua, [note, []])
  end

  def play(lua, [opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    {[synth | _rest], _lua} = :luerl.do(<<"return bleep_current_synth">>, lua)
    tag = "*"

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time_s, tag, {:synth, synth, output_id, opts}}
    )
  end

  def play(lua, [note, opts_table]) when is_integer(note) or is_float(note) do
    play(lua, [[{"note", note} | opts_table]])
  end

  def control_fx(lua, [opts_table]) when is_list(opts_table) do
    control_fx(lua, [fetch_current_output_id(lua), opts_table])
  end

  def control_fx(lua, [uuid]) when is_binary(uuid) do
    control_fx(lua, [uuid, []])
  end

  def control_fx(lua, [uuid, opts_table]) when is_list(opts_table) do
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    tag = "*"

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time_s, tag, {:core_control_fx, uuid, opts}}
    )
  end

  @impl true
  def handle_event("bleep-time", %{"time_s" => time_s, "latency" => latency}, socket) do
    socket = assign(socket, :kalman, Kalman.step(0, latency, socket.assigns.kalman))
    latency_est = Kalman.estimate(socket.assigns.kalman)

    {:noreply,
     socket
     |> assign(:bleep_latency, latency_est * 1000)
     |> push_event("bleep-time-ack", %{
       roundtrip_time: time_s,
       latency_est: latency_est,
       server_time: :erlang.system_time(:milli_seconds) / 1000
     })}
  end

  @impl true
  def handle_event("cue-code", %{"value" => code, "result_id" => result_id}, socket) do
    start_time_ms = :erlang.system_time(:milli_seconds)
    bar_duration_ms = 4 * 1000
    offset_ms = bar_duration_ms - rem(start_time_ms, bar_duration_ms)
    start_time_s = (start_time_ms + offset_ms) / 1000.0
    eval_code(start_time_s, code, result_id, socket)
  end

  @impl true
  def handle_event(
        "eval-code",
        %{"value" => code, "result_id" => result_id},
        socket
      ) do
    start_time_s = :erlang.system_time(:milli_seconds) / 1000
    eval_code(start_time_s, code, result_id, socket)
  end

  def eval_code(start_time_s, code, result_id, socket) do
    core_lua =
      if Mix.env() == :dev do
        File.read!(@core_lua_path)
      else
        @core_lua
      end

    lua = :luerl_sandbox.init()

    {_, lua} = :luerl.do(<<"bleep_start_time = #{start_time_s}">>, lua)
    {_, lua} = :luerl.do(<<"bleep_global_time = 0">>, lua)
    {_, lua} = :luerl.do(<<"bleep_current_synth = \"fmbell\"">>, lua)
    {_, lua} = :luerl.do(<<"bleep_current_fx_stack = { \"default\" }">>, lua)

    {_, lua} =
      :luerl.do(
        core_lua,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"play">>],
        fn args, state ->
          play(state, args)
          {[0], state}
        end,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"sample">>],
        fn args, state ->
          sample(state, args)
          {[0], state}
        end,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"control_fx">>],
        fn args, state ->
          control_fx(state, args)
          {[0], state}
        end,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"uuid">>],
        fn _args, state ->
          {[UUID.uuid4()], state}
        end,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"bleep_core_start_fx">>],
        fn args, state ->
          bleep_core_start_fx(state, args)
          {[0], state}
        end,
        lua
      )

    lua =
      :luerl.set_table(
        [<<"bleep_core_stop_fx">>],
        fn args, state ->
          bleep_core_stop_fx(state, args)
          {[0], state}
        end,
        lua
      )

    res_or_exception =
      try do
        :luerl_new.do_dec(code, lua)
      rescue
        e ->
          {:exception, e, __STACKTRACE__}
      end

    {:noreply,
     socket
     |> display_eval_result(res_or_exception, result_id)}
  end

  def display_eval_result(socket, {:exception, e, trace}, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: Exception.format(:error, e, trace),
      result_id: result_id
    })
  end

  def display_eval_result(socket, {:ok, result, _new_state}, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: "#{inspect(result)}",
      result_id: result_id
    })
  end

  def display_eval_result(socket, {:error, error, _new_state}, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: "Error - #{inspect(error)}",
      result_id: result_id
    })
  end

  def display_eval_result(socket, error, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: Kernel.inspect(error),
      result_id: result_id
    })
  end

  def lua_table_to_map(table) do
    Enum.reduce(table, %{}, fn
      {k, v}, acc when is_binary(k) ->
        Map.put(acc, String.to_atom(k), v)

      {k, v}, acc ->
        Map.put(acc, k, v)
    end)
  end

  def fetch_current_output_id(lua_state) do
    {[fx_id | _rest], _lua} =
      :luerl.do(<<"return bleep_current_fx_stack[#bleep_current_fx_stack]">>, lua_state)

    fx_id
  end

  @impl true
  def handle_info(
        %{topic: "room:bleep-audio", payload: {time_s, tag, {:core_stop_fx, uuid, opts}}},
        socket
      ) do
    {:noreply,
     sched_bleep_audio(socket, time_s, tag, %{
       time_s: time_s,
       cmd: "releaseFX",
       uuid: uuid,
       opts: opts
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time_s, tag, {:core_control_fx, uuid, opts}}
        },
        socket
      ) do
    {:noreply,
     sched_bleep_audio(socket, time_s, tag, %{
       time_s: time_s,
       cmd: "controlFX",
       uuid: uuid,
       opts: opts
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time_s, tag, {:core_start_fx, uuid, fx_id, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     sched_bleep_audio(socket, time_s, tag, %{
       time_s: time_s,
       cmd: "triggerFX",
       fx_id: fx_id,
       uuid: uuid,
       output_id: output_id,
       opts: opts
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time_s, tag, {:sample, sample_name, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     sched_bleep_audio(socket, time_s, tag, %{
       time_s: time_s,
       cmd: "triggerSample",
       sample_name: sample_name,
       output_id: output_id,
       opts: opts
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time_s, tag, {:synth, synth, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     sched_bleep_audio(socket, time_s, tag, %{
       time_s: time_s,
       cmd: "triggerOneshotSynth",
       synthdef_id: synth,
       output_id: output_id,
       opts: opts
     })}
  end

  def sched_bleep_audio(socket, time_s, tag, msg) do
    msg = Map.put(msg, :time_s, time_s + 0.5)

    push_event(socket, "sched-bleep-audio", %{
      time_s: time_s,
      tag: tag,
      msg: Jason.encode!(msg)
    })
  end
end

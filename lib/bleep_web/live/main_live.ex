defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @content_path Path.join([:code.priv_dir(:bleep), "content", "content_16_01_24.lua"])

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
    lua = Bleep.Lang.make_lua_vm("
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
      ")

    {:ok, result, _new_state} = Bleep.Lang.eval_lua(content_lua, lua)
    result = Bleep.Lang.lua_table_array_to_list(hd(result))

    Enum.map(result, fn frag_info ->
      frag_info = Bleep.Lang.lua_table_to_map(frag_info)
      frag_info = Map.put(frag_info, :uuid, UUID.uuid4())
      frag_info
    end)
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
    <div class="p-5 text-sm px-7 text-zinc-200">
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
    <div class="fixed top-0 left-0 z-50 flex items-center justify-between w-full text-sm border-b shadow-lg border-zinc-100 bg-zinc-950 backdrop-blur-md bg-opacity-70 border-b-zinc-600">
      <div class="flex items-center pl-7 gap">
        <a href="/">
          <img id="bleep-logo" src={~p"/images/bleep_logo.png"} width="200" phx-update="ignore" />
        </a>
        <p class="px-2 font-medium leading-6 rounded-full bg-brand/5 text-brand">
          v0.0.1
        </p>
      </div>
      <div class="float-right pr-7 text-zinc-100" id="bleep-time" phx-hook="BleepTime">
        <p class="font-mono text-xs text-zinc-200">
          Latency: <%= :erlang.float_to_binary(@bleep_latency, decimals: 2) %> ms
        </p>
      </div>
    </div>
    <div class="pt-20">
      <%= for frag <- @data do %>
        <.render_frag {frag} />
      <% end %>
    </div>
    """
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
    {:noreply, eval_and_display(socket, start_time_s, code, result_id)}
  end

  @impl true
  def handle_event(
        "eval-code",
        %{"value" => code, "result_id" => result_id},
        socket
      ) do
    start_time_s = :erlang.system_time(:milli_seconds) / 1000
    {:noreply, eval_and_display(socket, start_time_s, code, result_id)}
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

  def eval_and_display(socket, start_time_s, code, result_id) do
    res = Bleep.Lang.start_run(start_time_s, code)
    display_eval_result(socket, res, result_id)
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

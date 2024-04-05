defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @content_folder Path.join([:code.priv_dir(:bleep), "content"])

  @impl true
  def mount(params, _session, socket) do
    user_id = get_connect_params(socket)["bleep_user_id"]

    {:ok, _pid} = Registry.register(Registry.Bleep, user_id, self())

    artist = params["artist"] || "lets_all_make_brutalism"
    artist_path = artist_lua_path(artist)

    data =
      case :ets.lookup(:lua_content_cache, artist_path) do
        [{_, value}] ->
          value

        [] ->
          res = Bleep.Content.data_from_lua(artist_path)
          :ets.insert(:lua_content_cache, {artist_path, res})
          res
      end

    {:ok,
     socket
     |> assign(:user_id, user_id)
     |> assign(:bleep_latency, 50.0)
     |> assign(:frags, data[:frags])
     |> assign(:init_code, data[:init])
     |> assign(:author, data[:author])
     |> assign(:bleep_default_bpm, data[:default_bpm])}
  end

  def artist_lua_path(artist) do
    normalised =
      artist
      |> String.normalize(:nfd)
      |> String.replace(~r/[^0-9A-z-_]/u, "")

    Path.join([@content_folder, "#{normalised}.lua"])
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
    <div class="p-2 text-sm px-7 text-zinc-200">
      <%= Phoenix.HTML.raw(@markdown) %>
    </div>
    """
  end

  def render_frag(%{kind: "mermaid"} = assigns) do
    ~H"""
    <div class="p-8 bg-blue-100 border border-zinc-600 rounded-xl dark:bg-slate-100">
      <div class="mermaid" phx-update="ignore" id={@frag_id}>
        <%= @content %>
      </div>
    </div>
    """
  end

  def render_frag(%{kind: "editor"} = assigns) do
    frag_id = assigns[:frag_id]
    assigns = assign(assigns, :run_button_id, "run-button-#{frag_id}")
    assigns = assign(assigns, :cue_button_id, "cue-button-#{frag_id}")
    assigns = assign(assigns, :stop_button_id, "stop-button-#{frag_id}")
    assigns = assign(assigns, :monaco_path, "#{frag_id}.lua")
    assigns = assign(assigns, :monaco_id, "monaco-#{frag_id}")
    assigns = assign(assigns, :result_id, "result-#{frag_id}")

    ~H"""
    <div class="h-full pt-2 p-7">
      <div
        id={@frag_id}
        class=""
        phx-hook="BleepEditorHook"
        phx-update="ignore"
        data-language="lua"
        data-content={@content}
        data-editor-id={@frag_id}
        data-path={@monaco_path}
        data-result-id={@result_id}
        data-run-button-id={@run_button_id}
        data-cue-button-id={@cue_button_id}
        data-stop-button-id={@stop_button_id}
      >
        <button
          class="hidden px-2 py-1 font-bold text-white bg-orange-600 rounded hover:bg-orange-800"
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
        <button
          class="px-2 py-1 font-bold text-white bg-orange-600 rounded hover:bg-orange-800"
          id={@stop_button_id}
        >
          Stop
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
          <img id="bleep-logo" src={~p"/images/cnotf.png"} width="200" phx-update="ignore" />
        </a>
        <p class="px-2 font-medium leading-6 rounded-full bg-brand/5 text-brand">
          v0.0.1
        </p>
      </div>
      <div class="float-right pr-7 text-zinc-100" id="bleep-time">
        <p class="font-mono text-xs text-zinc-200">
          Latency: <%= :erlang.float_to_binary(@bleep_latency, decimals: 2) %> ms
        </p>
      </div>
    </div>
    <div class="pt-20">
      <%= for frag <- @frags do %>
        <.render_frag {frag} />
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event(
        "eval-code",
        %{"value" => code, "result_id" => result_id, "editor_id" => editor_id},
        socket
      ) do
    start_time_s = :erlang.system_time(:milli_seconds) / 1000
    {:noreply, eval_and_display(socket, editor_id, start_time_s, code, result_id)}
  end

  @impl true
  def handle_event(
        "stop-editor-runs",
        %{"editor_id" => editor_id},
        socket
      ) do
    user_id = socket.assigns.user_id
    Bleep.Lang.stop_editor_runs(user_id, editor_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "cue-code",
        %{"code" => code, "result_id" => result_id, "editor_id" => editor_id},
        socket
      ) do
    bpm = socket.assigns.bleep_default_bpm
    start_time_ms = :erlang.system_time(:milli_seconds)
    bar_duration_ms = round(4 * (60.0 / bpm) * 1000)
    offset_ms = bar_duration_ms - rem(start_time_ms, bar_duration_ms)
    start_time_s = (start_time_ms + offset_ms) / 1000.0
    {:noreply, eval_and_display(socket, editor_id, start_time_s, code, result_id)}
  end

  def display_eval_result(socket, {:exception, e, trace}, result_id) do
    socket
    |> push_event("update-luareplres", %{
      # lua_repl_result: Exception.format(:error, e, trace),
      lua_repl_result: "Exception",
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

  def display_eval_result(socket, {:lua_error, e, _state}, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: inspect(e),
      result_id: result_id
    })
  end

  def display_eval_result(socket, error, result_id) do
    socket
    |> push_event("update-luareplres", %{

      lua_repl_result: "Error",
      result_id: result_id
    })
  end

  def eval_and_display(socket, editor_id, start_time_s, code, result_id) do
    init_code = socket.assigns.init_code
    bpm = socket.assigns.bleep_default_bpm
    user_id = socket.assigns.user_id
    res = Bleep.Lang.start_run(user_id, editor_id, start_time_s, code, init_code, %{bpm: bpm})
    display_eval_result(socket, res, result_id)
  end

  @impl true
  def handle_info({:latency_update, latency}, socket) do
    {:noreply,
     socket
     |> assign(:bleep_latency, latency)}
  end

  def id_send(user_id, msg) do
    case Registry.lookup(Registry.Bleep, user_id) do
      [{pid, _value}] ->
        send(pid, msg)

      _ ->
        Logger.error("No LiveView process found for user #{user_id}")
    end
  end
end

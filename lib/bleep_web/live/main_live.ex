defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @content_folder Path.join([:code.priv_dir(:bleep), "content"])

  @impl true
  def mount(params, session, socket) do
    user_id = get_connect_params(socket)["bleep_user_id"]

    if connected?(socket) do
      {:ok, _pid} = Registry.register(Registry.Bleep, user_id, self())
    end

    case socket.assigns.live_action do
      :user -> mount_user(user_id, params, session, socket)
      _ -> mount_artist(user_id, params, session, socket)
    end
  end

  def mount_user(user_id, _params, _session, socket) do
    case :ets.lookup(:lua_user_content_cache, user_id) do
      [{_, data}] ->
        {
          :ok,
          socket
          |> assign(:user_id, user_id)
          |> assign(:bleep_ping, 20.0)
          |> assign_content_data(data)
        }

      [] ->
        mount_artist(user_id, %{"artist" => "new"}, %{}, socket)
    end
  end

  def mount_artist(user_id, params, _session, socket) do
    artist = params["artist"] || "init"
    artist_path = artist_lua_path(artist)
    data = get_artist_content(artist_path)

    {
      :ok,
      socket
      |> assign(:user_id, user_id)
      |> assign(:bleep_ping, 20.0)
      |> assign_content_data(data)
    }
  end

  def get_artist_content(artist_path) do
    code_reloading? = Application.get_env(:bleep, BleepWeb.Endpoint)[:code_reloader]

    if code_reloading? do
      Bleep.Content.data_from_lua_file(artist_path)
    else
      case :ets.lookup(:lua_content_cache, artist_path) do
        [{_, value}] ->
          value

        [] ->
          res = Bleep.Content.data_from_lua_file(artist_path)
          :ets.insert(:lua_content_cache, {artist_path, res})
          res
      end
    end
  end

  def data_from_assigns(socket) do
    %{
      title: socket.assigns.title,
      description: socket.assigns.description,
      # source: socket.assigns.source,
      frags: socket.assigns.frags,
      init: socket.assigns.init_code,
      author: socket.assigns.author,
      bpm: socket.assigns.bleep_default_bpm,
      quantum: socket.assigns.bleep_default_quantum,
      user_id: socket.assigns.user_id
    }
  end

  def assign_content_data(socket, data) do
    socket
    |> assign(:title, data[:title])
    |> assign(:description, data[:description])
    |> assign(:source, data[:source])
    |> assign(:frags, data[:frags])
    |> assign(:init_code, data[:init])
    |> assign(:author, data[:author])
    |> assign(:bleep_default_bpm, data[:default_bpm])
    |> assign(:bleep_default_quantum, data[:default_quantum])
  end

  def load_user_content(socket, content) do
    data = Bleep.Content.data_from_lua(content)
    :ets.insert(:lua_user_content_cache, {socket.assigns.user_id, data})
    assign_content_data(socket, data)
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
    <video
      class="p-8 align-middle rounded-xl"
      width="640"
      height="480"
      controls
      poster={"/videos/#{String.trim(@src)}_poster.png"}
    >
      <source src={"/videos/#{String.trim(@src)}.mp4"} type="video/mp4" />
      Your browser does not support the video tag.
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
    assigns = assign(assigns, :scope_id, "scope-#{frag_id}")

    ~H"""
    <div class="h-full pt-2 p-7">
      <div
        id={@frag_id}
        class="editor-container"
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
        data-scope-id={@scope_id}
      >
        <div class="flex">
          <button
            class="flex items-center justify-center px-2 mt-5 mb-0 mr-1 text-sm font-bold text-blue-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-blue-600 hover:text-zinc-200"
            id={@run_button_id}
            aria-label="Run code"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="12"
              height="12"
              viewBox="0 0 22 20"
              fill="none"
              stroke="#e4e4e7"
              stroke-width="1"
              class="mr-1"
            >
              <path d="M2 2 L18 10 L2 18 Z" />
            </svg>
            Run
          </button>

          <button
            class="flex items-center justify-center px-2 mt-5 mr-1 text-sm font-bold text-blue-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-blue-600 hover:text-zinc-200"
            id={@cue_button_id}
            aria-label="Cue code"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="12"
              height="12"
              viewBox="0 0 22 20"
              fill="none"
              stroke="#e4e4e7"
              stroke-width="1"
              class="mr-1"
            >
              <path d="M2 2 L10 10 L2 18 Z" />
              <path d="M12 2 L20 10 L12 18 Z" />
            </svg>
            Cue
          </button>

          <button
            class="flex items-center justify-center px-2 mt-5 mr-1 text-sm font-bold text-orange-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-orange-600 hover:text-zinc-200"
            id={@stop_button_id}
            aria-label="Stop code"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="12"
              height="12"
              viewBox="0 0 22 22"
              fill="none"
              stroke="#e4e4e7"
              stroke-width="1"
              class="mr-1"
            >
              <rect x="2" y="2" width="18" height="18" />
            </svg>
            Stop
          </button>

          <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50" class="ml-auto">
            <path id={@scope_id} style="stroke:url(#bleep-rgrad); stroke-width: 2px; fill: none;" />
          </svg>
        </div>

        <div class="h-full pt-3 pb-3 bg-black border rounded-sm border-zinc-800">
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
        <div id="file-upload" phx-hook="BleepLoadHook">
          <input type="file" id="bleep-load-input" accept=".lua" class="hidden" />
          <label
            for="bleep-load-input"
            class="flex items-center justify-center px-2 py-1 mt-2 font-bold text-orange-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-orange-600 hover:text-zinc-200"
          >
            Load
          </label>
        </div>
        <p id="bleep-load-input-error-message" style="color: red;"></p>
        <button
          id="bleep-save-button"
          phx-click="save"
          phx-hook="BleepSaveHook"
          class="flex items-center justify-center px-2 py-1 mt-2 font-bold text-orange-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-orange-600 hover:text-zinc-200"
        >
          Save
        </button>
      </div>
      <div class="float-right pr-7 text-zinc-100" id="bleep-time">
        <ul class="font-mono text-xs list-none text-zinc-200">
          <li>
            BPM: <%= @bleep_default_bpm %>
          </li>
          <li>
            Quantum: <%= @bleep_default_quantum %>
          </li>
          <li>
            Ping: <%= :erlang.float_to_binary(
              @bleep_ping,
              decimals: 0
            ) %> ms
          </li>
        </ul>

        <button
          phx-click="stop_all"
          class="flex items-center justify-center px-2 py-1 mt-2 font-bold text-orange-600 border rounded-sm border-zinc-600 bg-zinc-800 hover:bg-orange-600 hover:text-zinc-200"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 22 22"
            fill="#000000"
            stroke="#ea580c"
            stroke-width="2"
            class="mr-1"
          >
            <rect x="2" y="2" width="18" height="18" />
          </svg>
          Stop All
        </button>
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
  def handle_params(params, _uri, socket) do
    # Add logic to handle the parameters and update the socket
    {:noreply, assign(socket, :params, params)}
  end

  @impl true
  def handle_event("load", %{"content" => content}, socket) do
    max_file_size = 1024 * 50

    case byte_size(content) do
      size when size < max_file_size ->
        {:noreply,
         socket
         |> load_user_content(content)
         |> push_patch(to: "/user")}

      _size ->
        Logger.error("File size too large: #{byte_size(content)}")
        {:noreply, assign(socket, :error_message, "File size too large.")}
    end
  end

  @impl true
  def handle_event("save", _, socket) do
    {:noreply, push_event(socket, "save_content", %{content: data_from_assigns(socket)})}
  end

  @impl true
  def handle_event("stop_all", _value, socket) do
    user_id = socket.assigns.user_id
    Bleep.Lang.stop_all_runs(user_id)
    {:noreply, socket}
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
    quantum = socket.assigns.bleep_default_quantum
    start_time_ms = :erlang.system_time(:milli_seconds)
    bar_duration_ms = round(quantum * (60.0 / bpm) * 1000)
    offset_ms = bar_duration_ms - rem(start_time_ms, bar_duration_ms)
    start_time_s = (start_time_ms + offset_ms) / 1000.0
    {:noreply, eval_and_display(socket, editor_id, start_time_s, code, result_id)}
  end

  def handle_event(
        "run-code",
        %{"code" => code, "result_id" => result_id, "editor_id" => editor_id},
        socket
      ) do
    start_time_s = :erlang.system_time(:milli_seconds) / 1000.0

    {:noreply, eval_and_display(socket, editor_id, start_time_s, code, result_id)}
  end

  def display_eval_result(socket, {:exception, _e, _trace}, result_id) do
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

  def display_eval_result(socket, _error, result_id) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: "Error",
      result_id: result_id
    })
  end

  def eval_and_display(socket, editor_id, start_time_s, code, result_id) do
    if byte_size(code) > 1024 * 10 do
      display_eval_result(socket, {:error, "code too large to run", nil}, result_id)
    else
      init_code = socket.assigns.init_code
      bpm = socket.assigns.bleep_default_bpm
      user_id = socket.assigns.user_id
      res = Bleep.Lang.start_run(user_id, editor_id, start_time_s, code, init_code, %{bpm: bpm})
      display_eval_result(socket, res, result_id)
    end
  end

  @impl true
  def handle_info({:ping_update, ping}, socket) do
    {:noreply,
     socket
     |> assign(:bleep_ping, ping)}
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

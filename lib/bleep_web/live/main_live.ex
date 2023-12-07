defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    BleepWeb.Endpoint.subscribe("room:bleep-audio")
    {:ok, assign(socket, data: data())}
  end

  def data() do
    [
      %{
        uuid: "84325588-5b8e-11ee-a06c-d2957a874c38",
        kind: :markdown,
        content: """
        ## Introduction
        This is bleep. You code - it bleeps.
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-11ee-8e4c-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("ninth")
        play(36)
        sleep(1.0)
        """
      },
      # %{
      #   uuid: "8ga337ca-5b8e-11ee-a06c-d2957a874c38",
      #   kind: :video,
      #   src: "movies/bishi_movie.mov"
      # },
      %{
        uuid: "9869face-5b8e-11ee-bd22-d2957a874c38",
        kind: :mermaid,
        content: """
        flowchart LR
        oscillator["`**oscillator**
        +pitch
        +tune
        +waveform_mix
        `"]
        filter["`**filter**
        +cutoff
        +resonance
        `"]
        vca["`**VCA**`"]
        accent["accent"]
        envmod["`**env mod**
        `"]
        envelope["`**envelope**
        +decay`"]
            oscillator --> filter --> vca
            envelope --> envmod
            envmod --> filter
            envelope --> vca
            accent --> vca & filter
            vca --> out
        """
      },
      %{
        uuid: "9f458afc-5b8e-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        for i=1, 10 do
          play(50 + i)
          sleep(0.125)
        end
        """
      },
      %{
        uuid: "af94a406-5b8e-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Notes

        To do:
        * At the moment the distortion and delay effects are hardwired - need to factor them out into separate module so that they can be used more generally.
        """
      }
    ]
  end

  def render_frag(%{kind: :video} = assigns) do
    ~H"""
    <video class="align-middle rounded-xl" width="640" height="480" controls>
      <source src={@src} type="video/quicktime" /> Your browser does not support the video tag.
    </video>
    """
  end

  def render_frag(%{kind: :markdown} = assigns) do
    md = Earmark.as_html!(assigns[:content])
    assigns = assign(assigns, :markdown, md)

    ~H"""
    <div class="p-8 bg-blue-100 border border-gray-600 bottom-9 rounded-xl dark:bg-slate-100">
      <%= Phoenix.HTML.raw(@markdown) %>
    </div>
    """
  end

  def render_frag(%{kind: :mermaid} = assigns) do
    ~H"""
    <div class="p-8 bg-blue-100 border border-gray-600 rounded-xl dark:bg-slate-100">
      <div class="mermaid" phx-update="ignore" id={@uuid}>
        <%= @content %>
      </div>
    </div>
    """
  end

  def render_frag(%{kind: :editor} = assigns) do
    assigns = assign(assigns, :button_id, "button-#{assigns[:uuid]}")
    assigns = assign(assigns, :monaco_path, "#{assigns[:uuid]}.lua")
    assigns = assign(assigns, :monaco_id, "monaco-#{assigns[:uuid]}")

    ~H"""
    <div
      id={@uuid}
      class="flex w-100 h-60"
      phx-hook="BleepEditor"
      phx-update="ignore"
      data-language="lua"
      data-content={@content}
      data-monaco-id={@monaco_id}
      data-path={@monaco_path}
    >
      <button
        class="px-2 py-1 font-bold text-white bg-blue-500 rounded hover:bg-pink-600"
        id={@button_id}
      >
        Run
      </button>
      <div class="w-full h-full" id={@monaco_id} monaco-code-editor></div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= for frag <- @data do %>
      <div class="p-2 ">
        <.render_frag {frag} />
      </div>
    <% end %>

    <p id="luareplres"></p>
    """
  end

  def lua_time(lua) do
    {[global_time | _rest], lua} = :luerl.do(<<"return bleep_global_time">>, lua)
    {[start_time | _rest], _lua} = :luerl.do(<<"return bleep_start_time">>, lua)
    global_time + start_time
  end

  def sample(lua, args) do
    sample_name = Enum.at(args, 0)
    time = lua_time(lua)
    opts = %{}
    BleepWeb.Endpoint.broadcast("room:bleep-audio", "msg", {time, {:sample, sample_name, opts}})
  end

  def play(lua, args) do
    note = Enum.at(args, 0)
    time = lua_time(lua)
    opts = %{}
    opts = Map.put(opts, :note, note)
    {[synth | _rest], _lua} = :luerl.do(<<"return bleep_current_synth">>, lua)

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:synth, synth, opts}}
    )
  end

  @impl true
  def handle_event("eval-code", %{"value" => value}, socket) do
    lua = :luerl_sandbox.init()
    start_time = :erlang.system_time(:milli_seconds) / 1000.0
    {_, lua} = :luerl.do(<<"bleep_start_time = #{start_time}">>, lua)
    {_, lua} = :luerl.do(<<"bleep_global_time = 0">>, lua)
    {_, lua} = :luerl.do(<<"bleep_current_synth = \"fmbell\"">>, lua)

    {_, lua} =
      :luerl.do(
        <<"function sleep (t)
  bleep_global_time = bleep_global_time + t
end



function use_synth(s)
  bleep_current_synth = s
end

function shuffle(x)
shuffled = {}
for i, v in ipairs(x) do
	local pos = math.random(1, #shuffled+1)
	table.insert(shuffled, pos, v)
end
return shuffled
end

function pick(x)
return shuffle(x)[1]
end
">>,
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

    res_or_exception =
      try do
        :luerl_new.do_dec(value, lua)
      rescue
        e ->
          {:exception, e, __STACKTRACE__}
      end

    {:noreply,
     socket
     |> display_eval_result(res_or_exception)}
  end

  def display_eval_result(socket, {:exception, e, trace}) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: Exception.format(:error, e, trace)
    })
  end

  def display_eval_result(socket, {:ok, result, _new_state}) do
    result =
      Enum.map(result, fn el ->
        # IO.chardata_to_string(el)
        inspect(el)
      end)

    socket
    |> push_event("update-luareplres", %{lua_repl_result: "#{inspect(result)}"})
  end

  def display_eval_result(socket, {:error, error, _new_state}) do
    socket
    |> push_event("update-luareplres", %{lua_repl_result: "Error - #{inspect(error)}"})
  end

  def display_eval_result(socket, error) do
    socket
    |> push_event("update-luareplres", %{
      lua_repl_result: Kernel.inspect(error)
    })
  end

  @impl true
  def handle_info(
        %{topic: "room:bleep-audio", payload: {time, {:sample, sample_name, opts}}},
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "triggerSample",
           sample_name: sample_name,
           output_node_id: "default-modular",
           input: "",
           opts: opts
         })
     })}
  end

  @impl true
  def handle_info(
        %{topic: "room:bleep-audio", payload: {time, {:synth, synth, opts}}},
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "triggerOneshotSynth",
           synthdef_id: synth,
           output_node_id: "default-modular",
           input: "",
           # opts: %{note: note, dur: 0.5}
           opts: opts
         })
     })}
  end
end

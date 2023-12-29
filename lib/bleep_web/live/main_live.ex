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
        ### Patterns
        Two functions for playing patterns:

        **pattern(s)** takes a string **s** in x-xx form. Each time you call **next()**, true is returned
        if the current step in the pattern is an x and false otherwise, and the pattern moves to the next
        step. Spaces in the pattern are ignored (so you can group into fours or bars etc). Patterns are rings; 
        when the end of the pattern is reached the current step returns to the start. 
        You can force a return to the first step by calling **reset()**.

        **euclidean(h,n,p)** makes a euclidean pattern given the number of hits **h**, length of the sequence **n** and (optionally) 
        the phase **p**. A phase of p right-shifts the pattern to the right by p steps. As above, use the **next()** method to 
        step through the pattern. You can also call **reset()** to restart the pattern.
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-11ee-8e4c-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        sd = pattern("---- x--- ---- x---")
        hh = euclidean(9,16)
        bd = pattern("x--- --x- x--- ----")
        for k=1,4 do
          for i=1,16 do
            if (sd:next()) then
              sample("bishi_snare")
            end
            if (bd:next()) then
              sample("drum_bass_hard")
            end
            if (hh:next()) then
              sample("hat_bdu")
            end
            sleep(0.125)
            if (math.random()<0.2) then
              hh:reset()
            end
          end
        end
        """
      },
      # %{
      #   uuid: "8ga337ca-5b8e-11ee-a06c-d2957a874c38",
      #   kind: :video,
      #   src: "movies/bishi_movie.mov"
      # },
      #%{
      #  uuid: "9869face-5b8e-11ee-bd22-d2957a874c38",
      #  kind: :mermaid,
      #  content: """
      #  flowchart LR
      #  oscillator["`**oscillator**
      #  +pitch
      #  +tune
      #  +waveform_mix
      #  `"]
      #  filter["`**filter**
      #  +cutoff
      #  +resonance
      #  `"]
      #  vca["`**VCA**`"]
      #  accent["accent"]
      #  envmod["`**env mod**
      #  `"]
      #  envelope["`**envelope**
      #  +decay`"]
      #      oscillator --> filter --> vca
      #      envelope --> envmod
      #      envmod --> filter
      #      envelope --> vca
      #      accent --> vca & filter
      #      vca --> out
      #  """
      #},
        %{
        uuid: "af94a406-5b8e-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Scales
        I have added some functions for scales.
        """
      },
      %{
        uuid: "9f458afc-5b8e-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        -- CHRISTMAS EFFECTS HAMPER!
        -- Ho Ho Ho
        use_synth("sawlead")
        -- new feature! autopanning with variable stereo spread
        push_fx("auto_pan",{wetLevel=0.5,dryLevel=0.5,rate=0.1,spread=0.9})
        push_fx("reverb",{wetLevel=0.4})
        -- new feature! mono delay which can be panned left-right
        push_fx("mono_delay",{wetLevel=0.3,delay=0.4,pan=0.9})
        -- various phasers and flangers to try
        push_fx("pico_pebble",{wetLevel=1,dryLevel=0})
        -- push_fx("deep_phaser",{wetLevel=1,dryLevel=0})
        -- push_fx("thick_phaser",{wetLevel=1,dryLevel=0})
        -- push_fx("flanger",{wetLevel=1,dryLevel=0,delay=2,depth=1.95,feedback=0.94,rate=0.2})
        -- You must always demonstrate phasers with Jean Michel Jarre, it's the law
        p = {62,67,69,70,74,70,69,62,67,69,70,69,67,69,67,62,67,55}
        for i=1,4 do
        play(43,{cutoff=0.2,duration=1})
        for _, note in ipairs(p) do
        play(note,{cutoff=2,duration=0.18})
        sleep(0.2)
        end
        end
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
    <div class="mt-8 text-sm p-6 my-12 bg-gray-100 border border-gray-600 bottom-9 rounded dark:bg-slate-100">
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
    assigns = assign(assigns, :run_button_id, "run-button-#{assigns[:uuid]}")
    assigns = assign(assigns, :cue_button_id, "cue-button-#{assigns[:uuid]}")
    assigns = assign(assigns, :monaco_path, "#{assigns[:uuid]}.lua")
    assigns = assign(assigns, :monaco_id, "monaco-#{assigns[:uuid]}")

    ~H"""
    <div
      id={@uuid}
      class="-mt-12 flex-col w-100 h-60"
      phx-hook="BleepEditor"
      phx-update="ignore"
      data-language="lua"
      data-content={@content}
      data-monaco-id={@monaco_id}
      data-path={@monaco_path}
      data-run-button-id={@run_button_id}
      data-cue-button-id={@cue_button_id}
    >
      <button
        class="px-2 py-1 font-bold text-white bg-blue-500 rounded hover:bg-pink-600"
        id={@cue_button_id}
      >
        Cue
      </button>
      <button
        class="px-2 py-1 font-bold text-white bg-blue-500 rounded hover:bg-pink-600"
        id={@run_button_id}
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

  def bleep_core_start_fx(lua, [uuid, fx_id]) do
    bleep_core_start_fx(lua, [uuid, fx_id, []])
  end

  def bleep_core_start_fx(lua, [uuid, fx_id, opts_table]) do
    output_id = fetch_current_output_id(lua)
    time = lua_time(lua)
    opts = lua_table_to_map(opts_table)

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:core_start_fx, uuid, fx_id, output_id, opts}}
    )
  end

  def bleep_core_stop_fx(lua, [uuid]) do
    time = lua_time(lua)
    opts = %{}

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:core_stop_fx, uuid, opts}}
    )
  end

  def sample(lua, args) do
    output_id = fetch_current_output_id(lua)
    sample_name = Enum.at(args, 0)
    time = lua_time(lua)
    opts = %{}

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:sample, sample_name, output_id, opts}}
    )
  end

  def play(lua, [note]) when is_integer(note) or is_float(note) do
    play(lua, [note, []])
  end

  def play(lua, [opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    {[synth | _rest], _lua} = :luerl.do(<<"return bleep_current_synth">>, lua)

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:synth, synth, output_id, opts}}
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
    time = lua_time(lua)
    opts = lua_table_to_map(opts_table)

    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      {time, {:core_control_fx, uuid, opts}}
    )
  end

  @impl true
  def handle_event("cue-code", %{"value" => code}, socket) do
    start_time_ms = :erlang.system_time(:milli_seconds)
    bar_duration_ms = 4 * 1000
    offset_ms = bar_duration_ms - rem(start_time_ms, bar_duration_ms)
    start_time = (start_time_ms + offset_ms) / 1000.0
    eval_code(start_time, code, socket)
  end

  @impl true
  def handle_event("eval-code", %{"value" => code}, socket) do
    start_time = :erlang.system_time(:milli_seconds) / 1000.0
    eval_code(start_time, code, socket)
  end

  def eval_code(start_time, code, socket) do
    lua = :luerl_sandbox.init()

    {_, lua} = :luerl.do(<<"bleep_start_time = #{start_time}">>, lua)
    {_, lua} = :luerl.do(<<"bleep_global_time = 0">>, lua)
    {_, lua} = :luerl.do(<<"bleep_current_synth = \"fmbell\"">>, lua)
    {_, lua} = :luerl.do(<<"bleep_current_fx_stack = { \"default\" }">>, lua)

    core_lua_path = Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
    {:ok, core_lua} = File.read(core_lua_path)

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

  def lua_table_to_map(table) do
    Enum.reduce(table, %{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  def fetch_current_output_id(lua_state) do
    {[fx_id | _rest], _lua} =
      :luerl.do(<<"return bleep_current_fx_stack[#bleep_current_fx_stack]">>, lua_state)

    fx_id
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time, {:core_stop_fx, uuid, opts}}
        },
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "releaseFX",
           uuid: uuid,
           opts: opts
         })
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time, {:core_control_fx, uuid, opts}}
        },
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "controlFX",
           uuid: uuid,
           opts: opts
         })
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time, {:core_start_fx, uuid, fx_id, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "triggerFX",
           fx_id: fx_id,
           uuid: uuid,
           output_id: output_id,
           opts: opts
         })
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time, {:sample, sample_name, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "triggerSample",
           sample_name: sample_name,
           output_id: output_id,
           opts: opts
         })
     })}
  end

  @impl true
  def handle_info(
        %{
          topic: "room:bleep-audio",
          payload: {time, {:synth, synth, output_id, opts}}
        },
        socket
      ) do
    {:noreply,
     push_event(socket, "bleep-audio", %{
       msg:
         Jason.encode!(%{
           time: time,
           cmd: "triggerOneshotSynth",
           synthdef_id: synth,
           output_id: output_id,
           opts: opts
         })
     })}
  end
end

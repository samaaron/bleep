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
        uuid: "af94a406-5b8e-11ff-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Microphones and more reverbs
        I have added more reverbs and a small number of
        microphone impulse responses - so now if you want to listen to Bishi
        singing into a Sovet Lomo microphone in an abandoned nuclear
        reactor chamber, you can! Mics and reverbs can be chained together of course.
        See the README file in the impulses folder.
        """
      },
      %{
        uuid: "8e5f23a6-5b8e-2432-8e4c-d2957b474c38",
        kind: :editor,
        lang: :lua,
        content: """
        push_fx("mic_lomo",{wetLevel=1.2,dryLevel=0})
        push_fx("reverb_massive",{wetLevel=0.25,dryLevel=1})
        sample("bishi_verse")
        """
      },
      %{
        uuid: "af94a406-5b8e-76aa-8e3a-d29aca874ca8",
        kind: :markdown,
        content: """
        ### New patterns!
        Parameters are now rings.
        I intend to do the same for drum patterns too so we will have
        ```
        play_pattern(note_list,opts)
        ```
        and
        ```
        drum_pattern(xoxo_string,opts)
        ```
        which will have a consistent syntax with
        ```
        play(note,opts)
        ```
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-2432-8e4c-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")
        push_fx("stereo_delay", {leftDelay=0.3,rightDelay=0.6,feedback=0.2,wetLevel=0.2})
        push_fx("reverb", {wetLevel=0.2})
        -- pattern play has now been changed so that a list of parameters is passed
        -- all the parameters can be single values or rings
        -- if ring is shorter than note sequence we cycle around
        -- allows easy control of accents etc
        the_notes = {D4,G4,G4,A4,G4,Fs4,E4,E4}
        the_durs = {0.3,0.3,0.15,0.15,0.15,0.15,0.3,0.5}
        -- gate length is the proportion (0-1) that the note sounds for the given duration
        play_pattern(the_notes, {
          dur=the_durs,
          gate=0.4})
        sleep(0.5)
        -- longer gate for legato
        play_pattern(the_notes, {
          dur=the_durs,
          gate=0.95})
        sleep(0.5)
        -- we can add subtle emphasis by cycling through levels
        play_pattern(the_notes, {
          dur=the_durs,
          level={0.2,0.35},
          gate=0.5})
        sleep(0.5)
        -- or could do the same with cutoff
        play_pattern(the_notes, {
          dur=the_durs,
          cutoff={0.3,0.7},
          gate=0.5})
        sleep(0.5)
        -- or bends
        -- there is a bug in the editor - comments in the last line of a box get removed
        play_pattern({D4,D4,G4,A4,G4,Fs4,Fs4,E4}, {
          dur=the_durs,
          bend_time=0.5,
          bend={0,G4,0,0,0,0,E4,0},
          gate={0.5,1,0.5,0.5,0.5,0.5,1,0.5}})
        """
      },
       %{
        uuid: "af94f2f4-5b8e-11ff-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Putting the fun into functional programming
        If you want to go all functional then you can now use a map function on
        lua tables. Doesn't work on rings yet but it will. 
        """
      },
      %{
        uuid: "8e5f23a6-82bb-2432-8e4c-d2957b474c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")
        map(function (n)
          play(n, {duration=0.12})
          sleep(0.125)
        end, {C3,D3,E3,F3,G3})
        """
      },
      %{
        uuid: "af94a406-5b8e-19af-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Rings
        Closely based on the approach in Sonic Pi, with the following implemented:
        * `pick(n)` - selects n values in a new ring
        * `clone(n)` - like repeat in Sonic Pi (repeat is a Lua keyword so we cant use it), returns a new ring that contains n copies
        * `shuffle()` - returns a new ring that is random shuffle
        * `reverse()` - returns a new ring that is time-reversed
        * `stretch(n)` - duplicates each value n times, makes a new ring
        * `length()` - get the length of the ring
        * `head(n)` - makes a new ring from the first n elements
        * `tail(n)` - makes a new ring from the last n elements
        * `slice(a,b)` - returns a new ring sliced from a to b (first element is zero)
        * `concat(r)` - concatenates the current ring with r, returns a new ring
        * `multiply(s)` - returns a new ring, each element multiplied by s
        * `add(s)` - return a new ring, each element summed with s
        * `mirror()` - returns a mirror of the ring
        * `reflect()` - returns a mirror with the duplicate middle element removed
        * `sort()` - return a sorted ring
        ### chaining
        As in Sonic Pi I have written all these so that rings are immutable and operations return a copy,
        so you can chain operations together
        ### get and set
        In theory we should be able to use array index notation with a custom class in lua, e.g. myring[3]
        instead of myring:get(3). I have this working in a lua 5.3 installation but it doesn't work in luerl
        (I note that the docs for luerl say that metatables are not correctly implemented). I have commented
        that code out for the time being.

        This should now be fixed - in which case I can get ```play_pattern``` working on rings too.
        """
      },
      %{
        uuid: "9f458afc-5b8e-2a4b-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")
        push_fx("stereo_delay",{leftDelay=0.5,rightDelay=0.25,wetLevel=0.1})
        notes = ring({G3,B3,C4,E4})
        for i=0,16 do
          play(notes:get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- reversing
        for i=0,16 do
          play(notes:reverse():get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- adding a scalar
        for i=0,16 do
          play(notes:add(5):get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- shuffling
        for i=0,16 do
          play(notes:shuffle():get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- pick and clone
        for i=0,16 do
          play(notes:pick(2):clone(2):get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- stretch
        for i=0,16 do
          play(notes:stretch(4):get(i),{duration=0.1})
          sleep(0.125)
        end
        sleep(0.5)
        -- concatenation
        use_synth("rolandtb")
        part1 = ring({C3,C3,D3,C3,Ds3,C3,F3,Ds3})
        part2 = ring({F3,F3,G3,F3,Gs3,F3,As3,Gs3})
        gunn = part1:clone(2):concat(part2:clone(2))
        for i=0,32 do
          play(gunn:get(i),{duration=0.1,cutoff=0.4, resonance=0.3, env_mod=0.8,decay=0.2})
          sleep(0.125)
        end
        sleep(0.5)
        -- sorting
        for i=0,32 do
          play(gunn:sort():get(i),{duration=0.1,cutoff=0.5, resonance=0.4, env_mod=0.8,decay=0.2})
          sleep(0.125)
        end
        sleep(0.5)
        """
      },
      %{
        uuid: "aca5a604-1432-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Scales
        An implementation of scales, again very similar to Sonic Pi. A lot of scales are predefined which
        are just Lua tables of MIDI note intervals such as {1,2,1,1,2,1} etc. These can be fractional for
        microtonal scales. As in Sonic Pi, a scale is a Ring - so any of the functions above can be invoked
        on a scale.
        """
      },
      %{
        uuid: "96d5fafc-5cda-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        -- simple major scale demo

        use_synth("elpiano")
        notes = scale(major,C3,2)
        for i=0,14 do
            play(notes:get(i),{duration=0.19})
            sleep(0.2)
        end

        sleep(2)

        -- random gamelan
        -- scales can be microtonal!

        use_synth("fmbell")
        push_fx("stereo_delay",{wetLevel=0.1,leftDelay=0.4,rightDelay=0.6})
        -- new reverb impulse responses!
        push_fx("plate_large",{wetLevel=0.2})
        upper = scale(pelog_sedeng,D4,2):shuffle()
        lower = scale(pelog_sedeng,D3):shuffle()
        for i=0,32 do
            play(upper:get(i),{duration=0.15})
            if (i%3==0) then
            play(lower:get(i),{duration=0.15})
            end
            sleep(0.2)
        end
        """
      },
      %{
        uuid: "84325588-5b8e-11ee-a06c-d2957a874c38",
        kind: :markdown,
        content: """
        ### Patterns
        Two functions for playing patterns:

        **pattern(s)** takes a string **s** in x-xx form and returns a ring containing numerical values. "x" is
        mapped to 1 and "-" is mapped to zero. Digits 1-9 are mapped to 0.1 to 0.9. So the pattern can be used
        to represent sound level (velocity) as well as note ons.

        **euclidean(h,n,p)** makes a euclidean pattern given the number of hits **h**, length of the sequence **n** and (optionally)
        the phase **p**. A phase of p right-shifts the pattern to the right by p steps. A ring is returned with 0,1 values.
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-11ee-8e4c-d2942a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        sd = pattern("---- x--- ---- x---")
        hh = euclidean(9,16)
        bd = pattern("x--- --x- x--- ----")
        -- lots of new impulse responses to try!
        push_fx("plate_drums",{wetLevel=0.1})
        for i=0,31 do
          if (sd:get(i)>0) then
            sample("bishi_snare")
          end
          if (bd:get(i)>0) then
            sample("drum_bass_hard")
          end
          if (hh:get(i)>0) then
            sample("hat_bdu")
          end
          sleep(0.125)
        end

        sleep(0.5)

        use_synth("noisehat")
        sd = pattern("---- x--- ---- x---")
        hh = pattern("xx4- 5-3- x-4- x-51")
        bd = pattern("x--- --x- x--- ----")
        for i=0,31 do
          if (sd:get(i)>0) then
            sample("bishi_snare")
          end
          if (bd:get(i)>0) then
            sample("bishi_bass_drum")
          end
          if (hh:get(i)>0) then
            play(G6,{level=hh:get(i),decay=0.19})
          end
          sleep(0.125)
        end
        """
      },
      %{
        uuid: "af94a406-1432-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Effects
        The next box shows how to use auto pan, reverb, delay, phaser and flanger.
        """
      },
      %{
        uuid: "9f458afc-5cda-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
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
      },
      %{
        uuid: "af94c406-1432-11ee-8e3a-d2c57a361c38",
        kind: :markdown,
        content: """
        ### Putting it all together
        Techno track - the first part of The Black Dog's "Let's all make brutalism"
        """
      },
      %{
        uuid: "9f258afc-5c45-11ef-bd76-d29a7ff74c38",
        kind: :editor,
        lang: :lua,
        content: """
        bar=16
        use_synth("dognoise")
        push_fx("reverb_medium",{wetLevel=0.3})
        play(C3,{duration=16,cutoff=100,rate=0.1,level=0.2})
        play(C3,{duration=16,cutoff=400,rate=0.05,level=0.1, resonance=25})
        bass_drum = pattern("x-- x-- x- x-- --- x-")
        low_tom = pattern("--- --x -- --- --x --")
        bass_synth = pattern("xx-2 --x- -x2- ----")
        hi_hat = pattern("--x-")
        -- now have a convenience function for deciding if there is a beat
        for i=0,bar*4-1 do
          if hasBeat(bass_drum,i) then
            sample("bishi_bass_drum")
          end
          if hasBeat(low_tom,i) then
            sample("elec_flip")
          end
          sleep(0.12)
        end
        for i=0,bar*4-1 do
          if hasBeat(bass_drum,i) then
            sample("bishi_bass_drum")
          end
          if hasBeat(low_tom,i) then
            sample("elec_flip")
          end
          if hasBeat(bass_synth,i) then
            use_synth("dogbass")
            if bass_synth:get(i)<0.5 then
                play(A2,{volume=0.7,cutoff=800,bend=A7})
            else
                play(A2,{volume=2,cutoff=800})
            end
          end
          if hasBeat(hi_hat,i) then
            use_synth("noisehat")
            play(G6,{volume=0.2})
          end
          sleep(0.12)
        end
        """
      },
      %{
        uuid: "af94c406-1432-11ee-c3c3-d2c57a361c38",
        kind: :markdown,
        content: """
        Bass drum - cue this before the techno line below
        """
      },
      %{
      uuid: "9f258afc-5c45-11ef-r2d2-d29a7ff74c38",
      kind: :editor,
      lang: :lua,
      content: """
      bd = pattern("x---")
      for i = 0, 64 do
      if (bd:get(i) > 0) then
        sample("bd_sone")
      end
      sleep(0.125)
      end
      """
      },
      %{
        uuid: "ac242406-1432-11ee-c3c3-d2c57b817c38",
        kind: :markdown,
        content: """
        Sliding notes - essential for techno
        """
      },
      %{
      uuid: "9f258afc-5c45-44ef-r2d2-d29a7aa43c38",
      kind: :editor,
      lang: :lua,
      content: """
      t = 0.125 -- time step

      push_fx("stereo_delay", {wetLevel=0.15,feedback=0.2,leftDelay=2 * t,rightDelay=4 * t})
      push_fx("reverb_medium")

      use_synth("rolandtb")

      the_notes = {C3,Cs3,C3,C3,C3,C3,C4,C4,C3,C3,C3,C3,C3,Ds3,Cs3,C3}
      the_bends = {0,0,0,0,C4,0,0,Cs3,0,C4,0,0,0,0,0,0}
      -- need a better way of doing this 
      the_accents = {0.3,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.2,0.3,0.2}
      the_gates = {0.8,0.8,0.8,0.8,1,0.8,0.8,1,0.8,1,0.8,0.8,0.8,0.8,0.8,0.8}

      the_cutoff = 0.03

      for i = 1, 4 do
        play_pattern(the_notes, {
          dur=t,
          gate=the_gates,
          bend=the_bends,
          level=the_accents,
          env_mod=0.3,
          distortion=0.4,
          cutoff =the_cutoff,
          resonance=0.3})
        the_cutoff = the_cutoff + 0.04
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
    <div class="p-6 my-12 mt-8 text-sm border rounded border-zinc-600 text-zinc-200 bg-zinc-500 bottom-9 dark:bg-zinc-700">
      <%= Phoenix.HTML.raw(@markdown) %>
    </div>
    """
  end

  def render_frag(%{kind: :mermaid} = assigns) do
    ~H"""
    <div class="p-8 bg-blue-100 border border-zinc-600 rounded-xl dark:bg-slate-100">
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
    <div class="h-full">
      <div
        id={@uuid}
        class=""
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
        <div class="w-full h-full" id={@monaco_id} monaco-code-editor></div>
      </div>
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

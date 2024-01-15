defmodule BleepWeb.MainLive do
  require Logger
  use BleepWeb, :live_view

  @core_lua_path Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
  @core_lua File.read!(@core_lua_path)

  @impl true
  def mount(_params, _session, socket) do
    BleepWeb.Endpoint.subscribe("room:bleep-audio")
    kalman = Kalman.new(q: 0.005, r: 1, x: 0.05)

    {:ok,
     socket
     |> assign(:kalman, kalman)
     |> assign(:bleep_latency, 50.0)
     |> assign(:data, data())}
  end

  def data() do
    [
      %{
        uuid: "af94a406-5b8e-76aa-8e3a-d29aca874ca8",
        kind: :markdown,
        content: """
        ### Lua redux - Map function for rings and array indexing
        * Map function added as Sam suggested.
        * Indexing has been changed so that Rings start at 1, consistent with Lua tables (otherwise moving between
        rings and Lua tables will get very confusing I think).
        * Array indexes can now be used to set and get values in a Ring.
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-2432-8e4c-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")
        push_fx("reverb", {wetLevel=0.2})

        -- set up some notes

        the_notes = ring({C3,D3,E3,F3,G3})

        -- map function suggested by Sam

        the_notes:map(function (n)
          play(n, {duration=0.12})
          sleep(0.125)
        end)

        sleep(1)

        -- the map function returns a new Ring so can be chained
        -- there are easier ways of doing this obviously, but for a demo:

        the_notes:map(function (n)
          return n + 12
        end):map(function (n)
          play(n, {duration=0.12})
          sleep(0.125)
        end)

        sleep(1)

        -- the imperative way, using array index style
        -- indexes now count from 1 and of course wrap around

        for i = 1, 10 do
          play(the_notes[i], {duration=0.12})
          sleep(0.125)
        end
        """
      },
      %{
        uuid: "af94f2f4-5b8e-11ff-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Lua redux - some new Ring functions
        Two new functions for alternating notes and intercalating two Rings.
        """
      },
      %{
        uuid: "8e5f23a6-82bb-2432-8e4c-d2957b474c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")

        -- alternate adds a duplicate to each note in the Ring shifted by a given
        -- amount, in this case an octave down
        -- @sam I note that the auto formatting spaces out the minus sign in negative numbers

        the_notes = scale(harmonic_minor, C3, 1):alternate(- 12)
        the_notes:map(function (n)
          play(n, {duration=0.12})
          sleep(0.125)
        end)

        sleep(1)

        -- fuse two Rings by intercalating their notes
        -- I am sorry for the 1980s reference but it must be done

        use_synth("saveaprayer")
        push_fx("roland_chorus", {wetLevel=1,dryLevel=0})
        push_fx("mono_delay", {wetLevel=0.3,delay=0.375,pan=0.5,feedback=0.1})
        push_fx("reverb", {wetLevel=0.2})

        -- melody line

        duran = ring({D4,E4,F4,A4,C5,A4,C5,A4})

        -- make 8 identical pedal notes

        pedal = ring({D3}):clone(7)

        -- combine them

        duran_duran = duran:merge(pedal)

        for i = 1, 2 do
          duran_duran:map(function (n)
            play(n, {duration=0.12,level=1})
            sleep(0.125)
          end)
        end
        """
      },
             %{
        uuid: "aca5a604-1432-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Lua redux - playing patterns
        All the above is much easier using play_pattern

        This has a similar syntax to play - a note list and then a table of parameters

        The interesting bit is that parameters are now Rings (or made into Rings) so that you
        can cycle around them to get various creative effects.

        """
      },
          %{
        uuid: "38df837-5cda-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("fmbell")
        push_fx("reverb", {wetLevel=0.2})

        -- simple use

        play_pattern({C4,D4,E4}, {
            duration=0.2,level=0.8})
        sleep(1)

        -- first parameter can be a Lua table or a Ring (or a scale, which is a Ring)
        -- duration (or any parameter) can be a Ring and we cycle around the values

        play_pattern(scale(lydian, D4, 2), {
            duration={0.2,0.1},
            level={0.8,0.4}})
        sleep(1)

        -- gate controls the proportion (0-1) of the duration that the note sounds for
        -- this also shows cycling through cutoffs and different note sequences
        -- with the same rhythmic pattern

        use_synth("rolandtb")
        push_fx("stereo_delay", {wetLevel=0.3,feedback=0.2,leftDelay=0.5,rightDelay=0.25})
        for i = 1, 4 do
          the_notes = scale(phrygian_dominant, C2, 1):pick(8):clone(2)
          play_pattern(the_notes, {
            duration={0.5,0.125,0.125,0.25},
            gate={0.8,0.5},
            resonance=0.3,
            env_mod=0.5,
            cutoff={0.4,0.2,0.2}})
        end
        """
      },
      %{
        uuid: "af94a406-5b8e-19af-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Lua redux - Rings update
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
        * **NEW!** `alternate(n)` - make alternating intervals by duplicating each value and adding a constant
        * **NEW!** `merge(n)` - merge (intercalate) the values of two rings
        * **NEW!** `quantize(n)` - quantise values in the ring to nearest n 
        * **NEW!** `Ring.constant(n,v)` - make a Ring of size n with constant value v
        * **NEW!** `Ring.random(n,min,max)` - make a Ring of n random values between min and max
        * **NEW!** `Ring.range(n,min,max)` - make a range of n values between min and max

        ### chaining
        As in Sonic Pi I have written all these so that rings are immutable and operations return a copy,
        so you can chain operations together
        ### get and set
       Get and set functions are provided but you can now use standard array index notation on rings.
        """
      },
      %{
        uuid: "9f458afc-5b8e-2a4b-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        use_synth("sawlead")
        push_fx("stereo_delay", {leftDelay=0.5,rightDelay=0.25,wetLevel=0.1})

        -- initial sequence
        notes = ring({G3,B3,C4,E4,G4}):clone(2)
        play_pattern(notes, {duration=0.125,gate=0.8})
        sleep(0.5)
          
        -- reversing
        play_pattern(notes:reverse(), {duration=0.125,gate=0.8})
        sleep(0.5)

        -- adding a scalar
        play_pattern(notes:add(7), {duration=0.125,gate=0.8})
        sleep(0.5)

        -- shuffling
        play_pattern(notes:shuffle(), {duration=0.125,gate=0.8})
        sleep(0.5)

        -- pick and clone
        play_pattern(notes:pick(2):clone(4), {duration=0.125,gate=0.8})
        sleep(0.5)

        -- stretch
        play_pattern(notes:stretch(4), {duration=0.125,gate=0.8})
        sleep(0.5)

        -- quantise and random
        -- might provide a helper function for the random thing

        dur = Ring.random(16, 1 / 16, 1 / 2):quantize(1 / 16)
        play_pattern(scale(lydian, D3, 2), {
          duration = dur,
          gate = 0.8})      
        """
      },
      %{
        uuid: "9638abe-1432-11ee-8e3a-d2957a874c38",
        kind: :markdown,
        content: """
        ### Scales
        An implementation of scales, again very similar to Sonic Pi. A lot of scales are predefined which
        are just Lua tables of MIDI note intervals such as {1,2,1,1,2,1} etc. These can be fractional for
        microtonal scales. As in Sonic Pi, a scale is a Ring - so any of the functions above can be invoked
        on a scale.

        Demo updated 13/1/24 for indexing from 1 and using array index style.
        """
      },
      %{
        uuid: "96d5fafc-5cda-11ee-bd76-d2957a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        -- simple major scale demo

        use_synth("elpiano")
        notes = scale(major, C3, 2)
        play_pattern(notes, {
          duration=0.2,
          gate=0.9})
        sleep(1)

        -- random gamelan
        -- scales can be microtonal!

        use_synth("fmbell")
        push_fx("stereo_delay", {wetLevel=0.1,leftDelay=0.4,rightDelay=0.6})
        -- new reverb impulse responses!
        push_fx("plate_large", {wetLevel=0.2})
        upper = scale(pelog_sedeng, D4, 2):shuffle()
        lower = scale(pelog_sedeng, D3):shuffle()
        for i = 1, 32 do
          play(upper[i], {duration=0.15})
          if (i % 3 == 0) then
            play(lower[i], {duration=0.15})
          end
          sleep(0.2)
        end
        """
      },
      %{
        uuid: "84325588-5b8e-11ee-a06c-d2957a874c38",
        kind: :markdown,
        content: """
        ### Lua redux - Drum patterns
        Two functions for playing patterns:

        **drum_pattern(s,params)** plays a drum pattern in x-xx form. Spaces are ignored. Parameters (including the sample name) can be
        single values or rings. Characters other than - and space are mapped to a ring of sample names in the order they appear.

        **euclidean_pattern(h,n,p)** makes a euclidean pattern given the number of hits **h**, length of the sequence **n** and (optionally)
        the phase **p**. A phase of p right-shifts the pattern to the right by p steps. A string is returned in x-xx form which can be used
        with drum_pattern.
        """
      },
      %{
        uuid: "8e5a73a6-5b8e-11ee-8e4c-d2942a874c38",
        kind: :editor,
        lang: :lua,
        content: """
        -- drum pattern works like play_pattern

        drum_pattern("x--- --x- x--- ----", {
          sample="bishi_bass_drum",
          duration=0.125})
        sleep(1)

        -- we are limited to one drum sound per time step, but we can use any characters
        -- we like apart from space (ignored) and dash (rest)
        -- other characters are mapped to the ring of samples, if given, in the order
        -- they appear in the pattern string

        drum_pattern("xx-x S-x- xx-- S-xx", {
          sample={"bishi_bass_drum","bishi_snare"},
          duration=0.125})
        sleep(1)

        -- we can also add levels which cycle round to get a bit more feel

        drum_pattern("xxxx xxxo xxxx xoxo", {
          sample={"bishi_closed_hat","hat_cats"},
          level={1,0.3,0.5,0.3},
          duration=0.2})
        sleep(1)

        -- or we can mess with the sample rate
        -- there is also a helper function to make euclidean rhythms

        drum_pattern(euclidean_pattern(20, 32), {
          sample="drum_tom_lo_soft",
          level={1,0.3,0.2,1,0.3,0.2,1.0,0.4},
          rate={1,1,2},
          duration=0.1})
        sleep(1)

        -- finally we can mess with durations to get swing
        -- a helper function will calculate this for us and return a ring of durations
        -- swing_16ths(amount,duration)
        -- swing_8ths(amount,duration)

        dur = swing_16ths(30, 0.125)

        for i = 1, 2 do
          drum_pattern("Bxxx Sxxo Bxxx SxoS BxBx Sxxo Bxxx SxSS", {
          sample={"bishi_bass_drum","bishi_closed_hat","bishi_snare","hat_cats"},
          level={1,0.3,0.5,0.3},
          duration=dur})
        end

        -- not sure about the way samples are allocated actually
        -- would be much easier just to have explicit declarations
        -- x = "bishi_closed_hat", 
        -- S = "bishi_snare" etc
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
        This needs to be updated with new pattern play functions, haven't had time yet
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
        for i = 1, 16 do
          drum_pattern("x---", {
          sample="bd_sone",
          duration=0.125})
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
            duration=t,
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
      },
        %{
        uuid: "ac242406-4142-da26-c3c3-d2c57b817c38",
        kind: :markdown,
        content: """
        Bleeped on Bach - new patch, testing longer sequences with effects
        """
      },
      %{
        uuid: "9f258afc-9c4e-2a3d-r2d2-d29a7aa43c38",
        kind: :editor,
        lang: :lua,
        content: """
        t = 0.35
        push_fx("stereo_delay", {wetLevel=0.1,feedback=0.3,leftDelay=3 * t,rightDelay=2 * t})
        push_fx("reverb_large", {wetLevel=0.5})
        push_fx("pico_pebble", {wetLevel=1,dryLevel=0})

        use_synth("childhood")

        s = scale(major, C4, 1.5)
        root = 1
        for i = 1, 12 do
          play_pattern({s[root],s[root+4],s[root+7],s[root+9]}, {
            duration=t,
            lfo_depth=1,
            gate=0.7,
            level={0.5,0.3,0.3,0.3}})
          root = root + 7
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
    <div class="mt-4 text-sm px-7 text-zinc-200 bg-zinc-800 dark:bg-zinc-900">
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
        <div id={@result_id}></div>
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
      if(Mix.env() == :dev) do
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
    result =
      Enum.map(result, fn el ->
        # IO.chardata_to_string(el)
        inspect(el)
      end)

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
    Enum.reduce(table, %{}, fn {k, v}, acc -> Map.put(acc, k, v) end)
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

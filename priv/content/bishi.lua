
init = [[
  function hello(bar)
    return "Hello " .. bar
  end
]]

content = {
    markdown [[
    ### Who has seen the wind - Bishi
    ]],

    markdown [[
    ## Overdrive

    Overdrive and distortion are based on the same circuit with a pre gain (whack it
    up for more distortion), a post gain (to adjust the level since it will get compressed
    at high input gains) and a bandpass filter for shaping the tone. Overdrive has a gentle
    nonlinearity and distortion has a steeper one.
    ]],

    editor [[
    push_fx("overdrive",{
        preGain=0.5,
        postGain=0.3,
        frequency=1500,
        bandwidth=50})
    sample("loop_amen")
    ]],

    markdown [[
    ## Distortion
    ]],

    editor [[
    push_fx("distortion",{
        preGain=0.8,
        postGain=0.3,
        frequency=800,
        bandwidth=5})
    sample("loop_amen")
    ]],

    markdown [[
    Compressor test
    ]],

    editor [[
    push_fx("reverb_medium", {wetLevel=0.1})

    -- various settings stored as preset parameter lists, see core.lua
    -- COMPRESS_GENERIC
    -- COMPRESS_PEAKS
    -- COMPRESS_KICKS
    -- COMPRESS_CLASSIC
    -- COMPRESS_SNARE
    -- COMPRESS_MEDIUM
    -- COMPRESS_BRUTE
    -- COMPRESS_WALL
    -- COMPRESS_GENTLE
    -- COMPRESS_GLUE
    -- COMPRESS_ACOUSTIC
    -- COMPRESS_PRECISE

    push_fx("compressor",COMPRESS_MEDIUM)

    -- firestarter
    dur = swing_16ths(8, 0.14)
    for i = 1, 4 do
        drum_pattern("BxxxSxxSxSxxSxxx", {
        B="bd_sone",
        x="bishi_closed_hat",
        S="bishi_snare",
        level={1,0.1,0.8,0.1},
        duration=dur})
    end
    ]],

    markdown [[
    Bass drum and hi hat
    ]],

    editor [[
    push_fx("reverb", {wetLevel=0.1})
    use_synth("bishiwobble")
    for i = 1, 32 do
        play(C2)
        drum_pattern("B-x- --x- --x- --x-", {
                B="bishi_bass_drum",
                x="bishi_closed_hat",
                duration=0.25,
                level=1})
    end
    ]],

    markdown [[
    Syncopated snare
    ]],

    editor [[
    push_fx("reverb", {wetLevel=0.1})
    for i = 1, 32 do
        drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
                x="bishi_snare",
                level=0.2,
                duration=0.25})
    end
    ]],

    markdown [[
        Same again but through triplet delay and gated snare
        ]],

    editor [[
    push_fx("mono_delay", {delay=0.375,wetLevel=0.2,dryLevel=0.8})
    push_fx("ambience_gated", {wetLevel=1,dryLevel=0})
    for i = 1, 32 do
    drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
                x="bishi_snare",
                level=0.4,
                duration=0.25})
    end
    ]],

    markdown [[
    Synths
        ]],

    editor [[
    use_synth("bishibass")
    push_fx("mono_delay", {wetLevel=0.25,feedback=0.2,delay=0.375,pan=0.5})
    for i = 1, 32 do
        play_pattern({C3,C4,C3,C4,F3,G3,As3}, {
                    duration={0.75,3.25,0.75,1.25,0.75,0.75,0.5},
                    level=0.1})
    end
    ]],

    markdown [[
    Vocals
    ]],

    editor [[
    push_fx("reverb", {wetLevel=0.1})
    for i = 1, 2 do
        sample("bishi_ah")
        sleep(3)
        sample("bishi_ahah")
        sleep(5)
    end
    ]],

    editor [[
        push_fx("reverb", {wetLevel=0.1})
        for i = 1, 2 do
            sample("bishi_ah")
            sample("bishi_ah_harmony")
            sleep(3)
            sample("bishi_ahah")
            sample("bishi_ahah_harmony")
            sleep(5)
        end
    ]],
    editor [[
        push_fx("reverb_large", {wetLevel=0.25})
        for i = 1, 2 do
            sleep(1.25)
            sample("bishi_ah_call",{level=0.5})
            sleep(3.5)
            sample("bishi_ah_reply",{level=0.5})
            sleep(3.25)
        end
    ]],
    editor [[
        push_fx("reverb_large", {wetLevel=0.2})
        sample("bishi_verse")
    ]],
    markdown [[
        Cool synthy middle bit (what do we do about the sitar?)
    ]],
    editor [[
    use_synth("sawlead")
    push_fx("deep_phaser", {wetLevel=0.8,dryLevel=0.2})
    push_fx("mono_delay", {wetLevel=0.1,delay=0.5,pan=0.9})
    notes = ring({G5,F5,Ds5,C5})
    freq = range_ring(8, 0.1, 0.5)
    for i = 1, 16 do
        play_pattern(notes, {
            duration=0.25,
            cutoff=freq[i],
            gate=0.75,
            filter_mod=0.4,
            filter_attack=0.05,
        level={0.2,0.1,0.1,0.1}})
    end
    ]],
    editor [[
    use_synth("sawlead")
    push_fx("mono_delay", {wetLevel=0.1,delay=0.75,pan=- 0.9})
    notes = ring({G4,As4,C5}):clone(2)
    for i = 1, 4 do
        play_pattern(notes, {
            duration=0.25,
            cutoff=0.3,
            gate=0.9,
            filter_attack=0.05,
        level={0.1,0.05,0.05}})
        sleep(2.5)
    end
    ]],
    editor [[
    for i=1,2 do
        sample("bishi_down_dini")
        sleep(8)
    end
    ]]


}

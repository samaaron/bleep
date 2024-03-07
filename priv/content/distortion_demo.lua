bpm = 71

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {
    markdown [[
    ### Distortion demo
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

}

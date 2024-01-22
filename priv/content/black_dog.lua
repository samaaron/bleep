return {

    markdown "# Black Dog demo",

    editor [[
    drum_pattern("x-- x-t x- x-- --t x-",{
        x="bishi_bass_drum",
        t="elec_flip",
        level={1,1,1,1,1,0.2,1,1,1,1,1,1,1,0.2,1,1},
        duration=0.2
    })
    ]],

    editor [[
    drum_pattern("--x- --x- --x- --x-",{
        x="bishi_closed_hat",
        level=0.2,
        duration=0.2
    })
    ]],

}
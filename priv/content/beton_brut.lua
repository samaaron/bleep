bpm = 60

content = {

markdown [[
# The Black Dog : Beton Brut
https://open.spotify.com/track/14VanlH81jnANRHQKMSqoV?si=c9421c97d40e4450
]],

editor [[
-- set up fx
push_fx("mono_delay",{delay=1,feedback=0.5,wetLevel=0.5})
push_fx("reverb_large",{wetLevel=0.3})

-- background atmospherics
sample("vinyl_hiss",{level=0.7,loop=true})
use_synth("dognoise")
play(Cs3,{duration=32,cutoff=100,rate=0.1,level=0.2})
play(Cs3,{duration=32,cutoff=400,rate=0.05,level=0.15, resonance=25})

-- phrase 1
use_synth("breton")
play_pattern({Cs6,As5,Fs5},{
    level=0.6,
    duration={0.5,0.25,0.25}})
sleep(5)

-- noise swoosh
sample("burst_reverb",{rate=0.8,level=0.3})
sleep(2)

-- phrase 2
play_pattern({Cs6,As5,Fs5,Ds5,Fs5},{
    level=0.6,
    duration={0.5,0.25,0.75,0.25,0.25}})
sleep(6)

-- phrase 3
play_pattern({As3,As3,As3,As3,As3,As3,As4},{
    level={0.7,0.7,0.4,0.7,0.7,0.4,0.4},
    duration={0.375,0.375,0.25,0.375,0.375,0.25,0.5},
    bend={0,0,As4,0,0,As4,Fs4},
    bend_time={0.3}
})
sleep(1.5)

-- phrase 4
play_pattern({F4,F4,F4,F4,Ds4},{
    level={0.7,0.4,0.5,0.4,0.5},
    bend={0,Fs4,0,Fs4,0},
    bend_time=0.5,
    duration={0.7,0.3,0.7,0.3,0.7}
})

sleep(1)

-- noise swoosh
sample("burst_reverb",{rate=0.8,level=0.3})
sleep(0.3)

-- phrase 5
play_pattern({As5,As5,As5},{
    level={0.7,0.6,0.4},
    duration={0.375,0.375,0.25},
    bend={0,As4,As4},
    bend_time={0.3}
    })

sleep(1)

-- quiet bends
play_pattern({Ds4,Ds4},{
    level={0.2,0.2},
    duration={0.375,0.375},
    bend={0,F4},
    bend_time={0.3}
})

sleep(1.25)

-- phrase 6
play_pattern({F4,F4,F4,F4,Ds4},{
    level={0.7,0.4,0.5,0.4,0.3},
    bend={0,Fs4,0,Fs4,Ds5},
    bend_time=0.5,
    duration={0.7,0.3,0.7,0.3,0.7}
})

]],

}
bpm = 129

content = {

    markdown [[# The Black Dog : Let's All Make Brutalism
    https://open.spotify.com/track/0Nas5r6tE9UaWNj3PALMe4?si=fe53a474b3104e30
    ]],

    editor [[
use_synth("dognoise")
play(Cs3,{duration=64,cutoff=120,rate=0.1,level=0.1,resonance=10})
play(Cs3,{duration=64,cutoff=400,rate=0.04,level=0.1, resonance=15})
for i=1,32 do
    drum_pattern("x-- x-t x- x-- --t x-",{
        x="bishi_bass_drum",
        t="elec_flip",
        level={1,1,1,1,1,0.2,1,1,1,1,1,1,1,0.2,1,1},
        duration=0.25
    })
end
    ]],

    editor [[
use_synth("rolandtb")
notes={A2,A2,0,A2,0,A2,A2,0,A2,A2,A2,0,0,A4,A4,0}
bends={0,0,0,A3,0,0,0,0,0,0,A3,0,0,0,A2,0}
for i=1,8 do
    play_pattern(notes,{
        cutoff=800,
        duration=0.25,
        gate=0.3,
        level={0.3,0.2,0.2,0.2},
        bend=bends})
end
    ]],

    editor [[
for i=1,32 do
    drum_pattern("--x- --x- --x- --x-",{
        x="hat_bdu",
        level=0.2,
        duration=0.25
    })
end
    ]],

    editor [[
for i=1,32 do
    drum_pattern("--xx --x-",{
        x="hat_cab",
        level=0.1,
        duration=0.25
    })
end
    ]],

    editor [[
for i=1,32 do
    drum_pattern("xxxx xxxx xxxx xxxx",{
        x="bishi_closed_hat",
        level={0.1,0.03,0.1,0.03},
        duration=0.25
    })
    end
        ]],

    editor [[
    push_fx("mono_delay",{delay=1,feedback=0.2})
    push_fx("reverb_large",{wetLevel=0.2})
    use_synth("simplepulse")

    play(A5,{duration=0.5,level=0.4})
    sleep(0.5)
    play(A5,{duration=1,bend=A4,bend_time=0.1,level=0.3})
    ]],

    editor [[
    push_fx("reverb_massive",{wetLevel=0.4,dryLevel=0})
    for i=1,4 do
    sample("vinyl_hiss",{rate=32/i,level=0.2})
    sleep(0.25)
    end
    ]],

    editor [[
        sample("dogpad-a4",{level=0.8})
        ]],

    editor [[
    push_fx("mono_delay",{delay=1,feedback=0.2})
    push_fx("reverb_large",{wetLevel=0.2})
    use_synth("simplepulse")

    play(C6,{duration=0.5,level=0.4,volume=0.4})
    sleep(0.5)
    play(C6,{duration=1,bend=F5,bend_time=0.1,level=0.3,volume=0.4})
    sleep(3.5)

    play(As5,{duration=0.5,level=0.4})
    sleep(0.5)
    play(As5,{duration=1,bend=D5,bend_time=0.1,level=0.3,volume=0.4})
    sleep(1)
    play(D5,{duration=1,bend=G4,bend_time=0.1,level=0.3,volume=0.4})
    ]],

}
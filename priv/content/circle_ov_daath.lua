content = {

markdown [[
# Circle Ov Daath Demo (96 BPM)
https://open.spotify.com/track/2jUzOnlJZ9TbFwOZIP8Y7M?si=fe0837843553480f
]],

markdown [[
Main drum loop
]],

editor [[
for k=1,4 do
    for i=1,8 do
        drum_pattern("B-xx Bxxx B-x- Bx--",{
            duration=0.25,
            level={0.5,0.4},
            B="bd_sone",
            x="bd_fat"
        })
    end
end
]],

markdown [[
Synth bass with delay
]],

editor [[
use_synth("sweepbass")
push_fx("mono_delay",{delay=0.75,wetLevel=0.3})
push_fx("reverb_large",{wetLevel=0.1})
for k=1,4 do
    for i=1,4 do
        sleep(0.25)
        play(D3,{level=0.4,duration=0.75})
        sleep(2)
        if (i==4) then
            play(F2,{level=0.3,duration=0.6})
        else
            play(D2,{level=0.05,duration=0.5})
        end
        sleep(1.75)
    end
end
]],

markdown [[
Pulsed high frequency noise
]],

editor [[
use_synth("highnoise")
push_fx("auto_pan",{rate=0.1,wetLevel=1,dryLevel=0})
push_fx("reverb_large")
for k=1,8 do
    cut = rand_ring(16,4000,12000):sort():reverse()
    for i=1,16 do
        dur = math.random(1,4)*0.25
        play(C4, {
            level=0.02,
            volume=0.1,
            duration=dur,
        cutoff=cut[i]})
        sleep(dur)
    end
end
]],

markdown [[
Hats
]],

editor [[
push_fx("reverb_small",{wetLevel=0.4})
for i=1,16 do
    drum_pattern("xxxxxxxx",{
        duration=0.25,
        x="bishi_closed_hat",
        level={0.7,0.1,0.6,0.6,0.3,0.1,0.3,0.1}})
end
]],

markdown [[
Random atmospherics
]],

editor [[
use_synth("submarine")
push_fx("reverb_massive",{wetLevel=0.3})
notes = ring({G4,D5,D4})
for i=1,8 do
    notes = notes:shuffle()
    play(notes[1],{duration=1,release=2,attack=0.5,level=0.3,volume=0.5})
    sleep(8*math.random(1,3))
end
]],

}
return {

markdown [[
# India - Work in Progress
]],

markdown [[
Two quick demos of string synthesis, broadly based on the Karplus-Strong algorithm but with
some tricks to make it efficient in WebAudio. A slow attack combined with beating between
two similar pitches gets you a tanpura sound. Adding some flanging (the pico-pebble) helps 
to get a bit of a zingggg sound.
A shorter attack gives you a normal plucked string.    

I've also now added a simple bansuri flute sound. I have a better version that uses wave tables but
that has not been incorporated into bleep yet.

Cue the tanpura first and then the bansuri. You'll hear a (rather robotic) Indian classical music recital.

]],

editor [[
use_synth("tanpura")
push_fx("pico_pebble",{wetLevel=0.8,dryLevel=0.2})
push_fx("reverb_large",{wetLevel=0.4})
notes=ring({A2,D3,D3,D2})  
dur = ring({0.6,0.65,0.61,1.5})   
for i=1,48 do
    play(notes[i],{
        duration=4+math.random()*6,
        volume=0.3,
        detune=0.4+0.2*math.random(),
        level=0.3+math.random()*0.1})  
    sleep(dur[i])
end       
]],

editor [[
-- algorithmic random bansuri player
-- something to think about - hand-crafting pitch bends etc will be very hard
-- are there algorithmic rules we can follow?
-- this is a VERY crude staring point based on some observations from a paper I found
-- see paper in google drive here
-- https://drive.google.com/file/d/1vIUZv0XS1EZiFSF50ilOpjHnuuIVBsZo/view?usp=drive_link

use_synth("bansuri")
push_fx("reverb_large",{wetLevel=0.4})

-- two octave scale

notes=scale("raga_bhairavi",D4,2)
durs=ring({0.125,0.25,0.25,0.5,0.5,1,1.5})

for k=1,16 do

    -- phrases are often made of triads with the same duration and pitch difference < 3 
    -- triad can be ascending or descending

    delta = math.random(1,2)
    root = math.random(1+2*delta,notes:length()-2*delta)
    delta = delta*(-1)^math.random(1,2)
    triad = {notes[root],notes[root+delta],notes[root+delta*2]}

    -- all notes in the triad have the same duration
    -- note that durs contains duplicates to reduce the probabiliy of choosing
    -- very short or very long durations

    d = durs:shuffle():get(1)

    -- play the triad
    -- we bend between longer notes

    for i=1,3 do
        bnd=0
        -- only bend longer notes, and dont bend too far
        if (i<3) and (math.abs(delta)<2) and (d>0.125) then 
            bnd = triad[i+1]
        end
        play(triad[i],{bend=bnd,
        bend_time=0.3,
        duration = d*0.95,
        chiff=0.1,
        level=0.4+math.random()*0.1,
        volume=0.4,
        noise=0.6,
        rate=math.random()+3, -- random tremolo rate in range [3,4]
        depth=0.2 -- not much tremolo for most notes
        })
        sleep(d+math.random()*0.05) -- add random amount to loosen the timing a bit
    end

    -- maybe play a long note a the end of the triad
    -- with more chiff and tremolo

    if math.random()<0.3 then
    play(notes:shuffle():get(1),{
        duration=0.95,
        chiff=0.3,
        noise=0.7,
        level=0.5,
        volume=0.4,
        rate=math.random()+3, -- random tremolo rate in range [3,4]
        depth=0.6 -- more tremolo
    })
    sleep(1+math.random()*0.1)

    -- random pause for up to one bar

    sleep(0.25*math.random(0,4))

    end
end          
]],

editor [[
use_synth("pluck")
push_fx("reverb_large",{wetLevel=0.3})

notes = scale("major_pentatonic",G3,1):pick(32)

notes:map(function (n)
play(n,{duration=4,
cutoff=1200,
decay=4+math.random()*4,
level=math.random()*0.5+0.2})
sleep(0.2)
end)
]],

}
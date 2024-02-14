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

I'm going to try sitar next.
]],

editor [[
use_synth("tanpura")
push_fx("pico_pebble",{wetLevel=0.8,dryLevel=0.2})
push_fx("reverb_large",{wetLevel=0.4})
notes=ring({A2,D3,D3,D2})  
dur = ring({0.6,0.65,0.61,1.5})   
for i=1,16 do
    play(notes[i],{
        duration=4+math.random()*6,
        volume=0.5,
        detune=0.4+0.2*math.random(),
        level=0.3+math.random()*0.1})  
    sleep(dur[i])
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
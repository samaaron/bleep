return {

    markdown [[
    # India - Work in Progress
    ]],
    
    editor [[
    use_synth("tanpura")
    push_fx("pico_pebble",{wetLevel=0.8,dryLevel=0.2})
    push_fx("reverb_large",{wetLevel=0.4})
    notes=ring({A2,D3,D3,D2})  
    dur = ring({0.6,0.65,0.61,1.5})   
    for i=1,16 do
        play(notes[i],{
            duration=4+math.random()*4,
            volume=0.5,
            detune=0.4+0.2*math.random(),
            level=0.3+math.random()*0.1})  
        sleep(dur[i])
    end       
    ]],
    
    }
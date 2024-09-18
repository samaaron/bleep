-- Bleep Save

title = "The Black Dog - Please Stop Talking"
author = ""
user_id = "1645f6bc-041e-4ffc-bebb-06ebab2ec5ce"
description = ""
bpm = 75
quantum = 4

init = [[
-- this code is automatically
-- inserted before every run
]]

content = {

markdown [[
### The Black Dog - Please Stop Talking
]],


editor("Arpeggio", [[
-- long meandering arpeggio
--use_synth("chiral")
use_synth("dogbass")
push_fx("stereo_delay", {leftDelay=0.600,rightDelay=0.400,spread=0.3,feedback=0.5,dryLevel=0.8,wetLevel=0.4})
push_fx("reverb_medium", {dryLevel=0.3,wetLevel=0.8})
push_fx("eqthree", {lowFreq=600,highFreq=2000,lowGain=- 12,midGain=2,highGain=- 1})
push_fx("compressor", {threshold=- 8, knee=8, ratio=3, attack=0.012, release=0.230})
push_fx("gainpan", {level=1.5,pan=0})

cutoffValue = 400

arpeggioNotes = {E5,B4,{Fs2,B3},Fs5,E5,{Cs3,E4},E2,Fs2,Fs5,{E3,Fs4},B2,Cs3,{B3,Cs5},E3,E3,{E4,E5},{E2,Fs3},B3,Fs4,{B2,Cs4},E4,E2,Cs5,{E3,E4},Fs4,B2,E5,{Fs3,B4},Cs5,E3,{Cs4,E5},E5,Fs3,Fs2,{E4,Fs5},Cs4,Cs3,B4,E4,E3,E5,B4,{Fs2,B3},Fs5,E5,{Cs3,E4},E2,Fs2,{E3,Fs4},B2,Cs3,{B3,Cs5},E3,E3,{E4,E5},{E2,Fs3},B3,Fs4,{B2,Cs4},E4,E2,Cs5,{E3,E4},Fs4,B2,E5,{Fs3,B4},Cs5,E3,{Cs4,E5},E5,Fs3,Fs2,E4,Cs4,Cs3,B4,E4,E3}

-- base time
t = 0.5333333
arpeggioTiming = {t*2,t,t,t*2,t,t,t,t,t,t,t,t*2,t,t,t*2,t,t,t*2,t,t,t*2,t,t,t,t,t,t,t,t*2,t,t,t,t,t*2,t,t,t*2,t,t,t*2,t,t,t*2,t,t,t,t,t,t,t,t*2,t,t,t*2,t,t,t*2,t,t,t,t,t,t,t,t,t,t,t,t*2,t,t,t,t,t*2,t,t,t*2,t,t,}


for patternrepeat = 1, 4 do
  -- 16 bar arpeggio
  for eachNote = 1, 79 do

    -- play current note/s
    play(arpeggioNotes[eachNote], {
      level=0.9,
      duration=0.5,
      cutoff=randi(cutoffValue - 100, cutoffValue + 100),
      resonance=randf(0.5, 0.8),
      attack =0.05,
      decay=0.4,
      sustain=0.2,
      release=0.4})
    
    -- note delay before next
    sleep(arpeggioTiming[eachNote])
    
    -- adjust low pass filter cutoff
    if patternrepeat <= 2 then
      cutoffValue = cutoffValue + 10
    else
      cutoffValue = cutoffValue - 10
    end

  end 
end
]]),


editor("Mid Synths", [[
-- mid pads
use_synth("junopad")
push_fx("reverb_large", {dryLevel=0.8,wetLevel=0.9})
push_fx("eqthree", {lowFreq=400,highFreq=2400,lowGain=- 12,midGain=2,highGain=2})
push_fx("gainpan", {level=2,pan=- 0.4})

for patternrepeat = 1, 2 do
    -- simple pad sustain over 4 bars
  play({B2,Cs3,E3,Fs3}, {
        volume=0.9,
        duration=6.0,
        cutoff=randi(1000, 1500),
        resonance=0.8,
        attack=0.5,
        decay=4,
        sustain=0.8,
        release=1})
  sleep(16)
end
]]),


editor("Hi Synths", [[
-- hi synth
use_synth("synthstrings")
push_fx("chorus", {rate=0.2,spread=0.8,depth=0.2,dryLevel=0.3,wetLevel=0.9})
push_fx("stereo_delay", {leftDelay=0.250,rightDelay=0.500,feedback=0.4,dryLevel=0.6,wetLevel=0.7})
push_fx("reverb_large", {dryLevel=0.6,wetLevel=0.9})
push_fx("eqthree", {lowFreq=500,highFreq=1600,lowGain=- 10,midGain=0,highGain=2})
push_fx("compressor", {threshold=- 8, knee=8, ratio=3, attack=0.012, release=0.230})
push_fx("gainpan", {level=2,pan=0.5})

toneParams1 = {
        volume=0.5,
        duration=8,
        cutoff=randi(1200, 1600),
        resonance=0.12,
        attack=0.75,
        decay=4,
        sustain=0.8,
        release=2}
toneParams2 = {
        volume=0.6,
        duration=4,
        cutoff=randi(1200, 1900),
        resonance=0.25,
        attack=0.75,
        decay=4,
        sustain=0.8,
        release=2}

-- part 1 (not used)
--for patternrepeat = 1, 2 do
    -- simple pad sustain over 4 bars
  --play({B2,Cs3,E3,Fs3}, toneParams1)
  --sleep(16)
--end

-- part 2
for patternrepeat = 1, 2 do
    -- simple pad sustain over 4 bars
  play({B2,Cs3,E3,Fs3}, toneParams1)
  play({Cs4}, toneParams2)
  sleep(6)
  play({B3}, toneParams2)
  sleep(10)
    -- variation
  play({B2,Cs3,E3,Fs3}, toneParams1)
  play({Fs4}, toneParams2)
  sleep(6)
  play({E4}, toneParams2)
  sleep(10)   
end

-- part 3
for patternrepeat = 1, 2 do
  play({B3,Cs4,E4,Fs4}, toneParams1)
  play({Cs3}, toneParams2)
  sleep(6)
  play({B2}, toneParams2)
  sleep(10)
    -- variation
  play({B3,Cs4,E4,Fs4}, toneParams1)
  play({Fs3}, toneParams2)
  sleep(6)
  play({E3}, toneParams2)
  sleep(10)   
end



]]),


editor("Bass", [[
-- low synth
use_synth("thickbass")
push_fx("reverb_large", {dryLevel=1,wetLevel=0.3})
push_fx("eqthree", {lowFreq=90,highFreq=2000,lowGain=- 2,midGain=4,highGain=- 2})
push_fx("gainpan", {level=1.5,pan=0.7})

-- B1,Fs1,E1,Fs1

for patternrepeat = 1, 2 do
    -- simple pad sustain over 4 bars
  play_pattern({B2,Fs2,E2,Fs2}, {
        volume=0.9,
        duration=3.2,
        cutoff=randi(400, 500),
        resonance=0.05,
        attack=0.2,
        decay=1,
        sustain=0.5,
        release=0.2})
end
]]),


editor("FX", [[
-- background fx
use_synth("noise")
push_fx("reverb_massive", {dryLevel=0,wetLevel=0.9})
push_fx("overdrive", {preGain=0.8,postGain=0.1,frequency=1000,bandwidth=2})
push_fx("reverb_massive", {dryLevel=0,wetLevel=0.9})
push_fx("eqthree", {lowFreq=140,highFreq=2400,lowGain=- 18,midGain=5,highGain=- 2})

for patternLoop = 1, 4 do

  play(C2, {
        volume=0.5,
        cutoff=randi(200, 2000),
        resonance=randf(0.1, 0.7),
        duration=8,
        attack=3,
        decay=3,
        sustain=0.8,
        release=8})
  sleep(6)

  sample("burst_reverb", {
        duration=4,
        rate=randf(0.25, 0.75),
        level=randf(0.1, 0.2)})
  sleep(10) 

end]]),


editor("FX Hi", [[
-- High FX
push_fx("stereo_delay", {leftDelay=0.600,rightDelay=0.800,spread=0.9,feedback=0.8,dryLevel=0.7,wetLevel=0.3})
push_fx("reverb_massive", {dryLevel=0.2,wetLevel=0.9})
push_fx("compressor", {threshold=- 10, knee=8, ratio=2, attack=0.012, release=0.230})

samples = {"elec_ping","elec_triangle","elec_plip","elec_blip","elec_blip2","elec_chime"}

-- just a single trigger, sample picked at random from the list
--for patternRepeat = 1, 8 do
  --sleepInit = randi(0, 4)
  --sleep(sleepInit)
sample(samples[dice(6)], {
        duration=4,
        rate=randf(1.00, 3.00),
        level=randf(0.6, 0.9)})
  --sleep(8 - sleepInit)
--end

]]),


editor("Metronome", [[
-- metro (32 bars)
push_fx("reverb_small", {dryLevel=0.5,wetLevel=0.4})

for i = 1, 32 do
  drum_pattern("MMMM", {
            duration=1,
            rate=3,
            level={0.8,0.4,0.6,0.4},
            M="hat_sci"})
end
]]),


editor("SEQUENCE", [[
-- arrangent of parts for song structure
bar = 4

run("FX")
sleep(bar * 2)

--run("FX Hi")
run("Arpeggio")
sleep(bar * 8)

-- run("Bass")
-- sleep(bar * 8)

-- run("Hi Synths")
-- sleep(bar * 8)

run("Mid Synths")
run("Bass")
sleep(bar * 8)

run("Hi Synths")
run("Bass")
sleep(bar * 8)

-- run("Bass")
-- run("Hi Synths")
-- sleep(bar * 8)


]]),


editor [[ ]],


} -- end content

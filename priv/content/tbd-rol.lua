-- Bleep Save

title = "The Black Dog - ROL"
author = ""
user_id = "2e295afb-48cb-41b6-930c-ade68ebf017e"
description = ""
bpm = 104
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {

markdown [[
# The Black Dog - ROL
]],

markdown [[
"This is an early demo of an unfinished and unreleased track, developed entirely in this software." - tBd
]],


markdown [[
### The Individual Parts
Use the Launcher panel on the right to trigger parts and play a live mix. There are loops programmed into the parts, but remember to enable "Loop" mode first if you want code blocks to repeat automatically! You can also edit the code to create your own remix. 
]],


editor("Slow Arp", [[
-- slow arp
use_synth("chiral")
push_fx("stereo_delay", {leftDelay=0.500,rightDelay=0.375,feedback=0.5,dryLevel=0.5,wetLevel=0.6})
push_fx("reverb_large", {dryLevel=0.4,wetLevel=0.6})
push_fx("eqthree", {lowFreq=700,highFreq=2800,lowGain=- 8,midGain=0,highGain=0})
push_fx("gainpan", {level=1.2,pan=- 0.3})

cutoffValue = 500
transpose = 0

-- 16 bar loop
for patternrepeat = 1, 16 do
  -- 4 bar pattern
  play_pattern({C4+transpose,G3+transpose,C5+transpose,G4+transpose,D4+transpose,F3+transpose,As4+transpose,G4+transpose}, {
      level=0.8,
      duration=2.00,
      cutoff=randi(cutoffValue - 100, cutoffValue + 100),
      resonance=randf(0.5, 0.8),
      symmetry=randf(- 1.0, 1.0),
      symmetry_mod=0.7,
      noise=0.2,
      attack =1,
      decay=0.5,
      sustain=0.8,
      release=1})
  cutoffValue = cutoffValue + 100
end
]]),


editor("Low Synth", [[
use_synth("analoguelead")
push_fx("stereo_delay", {leftDelay=0.250,rightDelay=0.500,feedback=0.4,dryLevel=0.6,wetLevel=0.5})
push_fx("reverb_large", {dryLevel=0.6,wetLevel=0.4})
push_fx("eqthree", {lowFreq=600,highFreq=2800,lowGain=5,midGain=1,highGain=- 2})
push_fx("compressor", {threshold=- 8, knee=8, ratio=3.5, attack=0.012, release=0.230})
push_fx("gainpan", {level=1.8,pan=0})

notes = {C1,{C2,C1}}
for playnotes = 1, 2 do
  play(notes[playnotes], {
    volume=0.8,
    duration=4.00,
    cutoff=randi(900, 1400),
    resonance=1.1,
    attack =1,
    decay=0.5,
    sustain=0.8,
    release=1})
  sleep(16)
end


notes = {C2,G1,C2,G1,As1}
for patternLoop = 1, 2 do
  for playnotes = 1, 5 do
    play(notes[playnotes], {
    volume=0.7,
    duration=2.40,
    cutoff=randi(1400, 1700),
    resonance=0.1,
    attack =1,
    decay=0.5,
    sustain=0.8,
    release=2})

    if playnotes == 1 or playnotes == 3 or playnotes == 4 then
      sleep(4)
    end
    if playnotes == 2 then
      sleep(12)
    end
    if playnotes == 5 then
      sleep(8)
    end
  end
  
end
]]),


editor("Big Chords", [[
-- chords
use_synth("analoguelead")
push_fx("chorus", {rate=0.2,spread=0.8,depth=0.25,dryLevel=0.1,wetLevel=0.7})
push_fx("stereo_delay", {leftDelay=0.250,rightDelay=0.500,feedback=0.5,dryLevel=0.2,wetLevel=0.8})
push_fx("reverb_large", {dryLevel=0.2,wetLevel=0.8})
push_fx("eqthree", {lowFreq=500,highFreq=2800,lowGain=- 10,midGain=3,highGain=1})
push_fx("gainpan", {level=1.2,pan=0})

cutoff = 1000

for patternrepeat = 1, 8 do

  play({C4,G4}, {
      volume=0.7,
      duration=6.00,
      cutoff=cutoff,
      resonance=0.1})
  sleep(8)
  play({As4,D5}, {
      volume=0.7,
      duration=4.00,
      cutoff=cutoff - 300,
      resonance=0.1})
  sleep(4)
  play({G4,C5}, {
      volume=0.7,
      duration=4.00,
      cutoff=cutoff - 600,
      resonance=0.1})
  sleep(4)
  cutoff = cutoff + 300

end
]]),


editor("High Arp", [[
use_synth("sweepbass")
push_fx("stereo_delay", {leftDelay=0.250,rightDelay=0.500,feedback=0.5,wetLevel=0.7})
push_fx("reverb_large", {dryLevel=0.4,wetLevel=0.5})
push_fx("eqthree", {lowFreq=800,highFreq=2800,lowGain=- 18,midGain=0,highGain=2})
push_fx("gainpan", {level=1.2,pan=0.4})

--cutoff = 1000
notes = ring({C5,G5,C5,G5,As5,D6,G5,C6})

-- 16 bars
for patternrepeat = 1, 8 do
  for i = 1, 8 do
    play(notes[i], {
            volume=0.7,
            duration=0.500,
            cutoff=randi(500, (900 * i)),
            resonance=0.3})
    sleep(1)
  end
  --cutoff = cutoff + 300

end
sleep(4)
]]),


editor("FX", [[
--fx
push_fx("eqthree", {lowFreq=400,highFreq=2800,lowGain=- 18,midGain=- 2,highGain=3})
push_fx("stereo_delay", {leftDelay=0.432,rightDelay=0.577,feedback=0.7,wetLevel=0.8})
push_fx("reverb_large", {dryLevel=0.3,wetLevel=0.8})
push_fx("gainpan", {level=1.2,pan=0})

for looper = 1, 16 do
  sleepInit = randi(0, 4)
  sleep(sleepInit)
  sample("ambi_dark_woosh", {
      rate=randf(0.2, 0.75),
      level=randf(0.3, 0.4),
      cutoff=randi(800, 2000)})
  sleep(8 - sleepInit)
end
sleep(4)

]]),


markdown [[
### The Test Arrangement
Just hit *Run* to start the track. This uses the Run() command to trigger the individual code blocks at the correct time.
]],



editor("SEQUENCE", [[
-- SEQUENCE
bar = 4 -- do the sleep in bars not beats

run("FX")
sleep(2)

run("Slow Arp")
sleep(bar * 8)

run("Low Synth")
sleep(bar * 16)

run("Big Chords")
sleep(bar * 8)

run("High Arp")
run("Low Synth")
sleep(bar * 2)

run("FX")
sleep(bar)


-- finish with fx
sample("misc_cineboom", {rate=0.15,level=0.2,cutoff=800})
sleep(2)
sample("misc_cineboom", {rate=0.1,level=0.1,cutoff=800})
sleep(2)
sample("misc_cineboom", {rate=0.075,level=0.05,cutoff=500})
sleep(10)

]]),





markdown [[
V20240922
]],




} -- end content

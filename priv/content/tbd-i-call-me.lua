-- Bleep Save

title = "The Black Dog - I Call Me"
author = ""
user_id = "2e295afb-48cb-41b6-930c-ade68ebf017e"
description = ""
bpm = 110
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {


markdown [[
# The Black Dog - I Call Me
From the "Seclusion EP":  
https://theblackdog.bandcamp.com/album/seclusion-ep
https://www.duststore.com/collections/all/products/seclusion-ep 
]],


markdown [[
"While the arpeggio part was came from an Ableton Live project, all the other parts were developed here and later rerecorded for the final track." - tBd
]],


markdown [[
### The Individual Parts
Use the Launcher panel on the right to trigger parts and play a live mix. Remember to switch on "Loop" mode first if you want code blocks to repeat automatically! Then edit the code to create your own remix. 
]],


editor("Keys", [[
-- keys
use_synth("chiral", {attack=0,decay=0.50,sustain=0.3,release=0.5})
push_fx("eqthree", {lowFreq=500,highFreq=1900,lowGain=- 10,midGain=1,highGain=- 2})
push_fx("chorus", {rate=0.3,spread=0.7,depth=0.2,dryLevel=0.7,wetLevel=0.8})
push_fx("reverb_large", {dryLevel=0.9,wetLevel=0.6})
push_fx("stereo_delay", {leftDelay=0.540, rightDelay=0.550, spread=0.6, feedback=0.4, drylevel=0.45, wetLevel=0.55})
push_fx("gainpan", {level=1.4,pan=- 0.3})

chords = {{{C4,A4,A5},{D4,C5,A5},{A3,A4,E5},{C4,A4,A5}},{{A3,E4,D5},{A3,A4,E5},{D4,C5,A5},{A3,E4,D5}},{{C4,A4,A5},{D4,C5,A5},{A3,A4,E5},{C4,A4,A5}},{{A3,F4,D5},{A3,A4,E5},{D3,C4,A5},{A3,E4,D5}}}
chordsleep = {0.5,1.0,1.5,0.5}
chordduration = 0.2

for patternloop = 1, 16 do
  -- 4 bar loop
  lpfmod = 0
  for barcount = 1, 4 do    
    sleep(0.5)
    for onebarloop = 1, 4 do
      play(chords[barcount][onebarloop], {
        duration=chordduration,
        cutoff=(randi(350, 600) + lpfmod),
        volume=randf(0.5, 0.8),
        gain=0.59,
        symmetry=- 0.59,
        attack=0.01,
        decay=0.50,
        sustain=0.3,
        release=0.75})
      sleep(chordsleep[onebarloop])
      -- adjust the low pass filter value
      lpfmod = lpfmod + 8
    end
  end
end
sleep(4)]]),


editor("Bass", [[
-- bassline
use_synth("rolandtb")
push_fx("compressor", {threshold=- 8, knee=8, ratio=5, attack=0.012, release=0.140})
push_fx("mono_delay", {delay=0.6, wetLevel=0.28})
push_fx("reverb_medium", {wetLevel=0.2})
push_fx("eqthree", {lowFreq=400,highFreq=2000,lowGain=5,midGain=- 3,highGain=- 3})
push_fx("gainpan", {level=1.5,pan=0})

for patternrepeats = 1, 6 do
  -- one pass == 8 bars
  notes1 = {A1,A1,A1,A1,A1,A2,A1,A1,A2,A1,A1,A1,A1,A2,A1,A1,A1,A1,A1,A1,A2,A1,A1,A2,A1,A1,A1,A1,A2,A1}
  notes2 = {A1,A1,A1,A1,A1,A2,A1,F1,F2,F1,F1,F1,F1,F2,F1,D1,D1,D1,D1,D1,D2,D1,A1,A2,A1,A1,A1,D2,D3,D2}
  notesBend1 = {0,0,0,0,0,A3,0,0,0,0,0,0,0,A3,0,0,0,0,0,0,A3,0,0,0,0,0,0,0,A3,0}
  notesBend2 = {0,0,0,0,0,A3,0,0,0,0,0,0,0,F3,0,0,0,0,0,0,D3,0,0,0,0,0,0,0,D3,0}
  notesleeps = {0.5,1,1.5,1,0.5,1,2.5,0.25,0.25,1,1.5,1,0.5,1,2.5,0.5,1,1.5,1,0.5,1,2.5,0.25,0.25,1,1.5,1,0.5,1,2}

  -- change me and retrigger to adjust pattern
  if patternrepeats <= 2 or patternrepeats == 5 then
    thisNotes = notes1
    notesBend = notesBend1
  else
    thisNotes = notes2
    notesBend = notesBend2
  end
  --thisNotes = notes2
  
  -- play me
  sleep(0.50)
  for patternloop = 1, 30 do
    play(thisNotes[patternloop], {
      duration=0.25,
      sin_level=0.3,
      saw_level=0.4,
      attack=0.02,
      decay=0.25,
      sustain=0.2,
      release=0.1,
      level=0.80,
      bend=notesBend[patternloop],
      bend_time=0.3,
      cutoff=randi((300 + (patternrepeats * 200)), (1200 + (patternrepeats * 500))),
      resonance=1 + randi(1, patternrepeats) + (0.1 * patternloop)})
    sleep(notesleeps[patternloop])
  end

end
sleep(4)
]]),


editor("Lead", [[
-- distorted synth lead
use_synth("junopad")
push_fx("eqthree", {lowFreq=800,highFreq=2400,lowGain=- 8,midGain=- 3,highGain=1})
push_fx("stereo_delay", {delay=0.25, feedback=0.3, drylevel=0.5, wetLevel=0.50})
push_fx("chorus", {rate=0.20,spread=0.8,depth=0.12})
push_fx("reverb_massive", {dryLevel=0.2, wetLevel=0.8})
push_fx("gainpan", {level=0.4,pan=0.6})

-- overdrive/distortion?
-- add values to incease fx through track?
push_fx("distortion", {preGain=1.0,postGain=0.08})
push_fx("reverb_massive", {dryLevel=0.3, wetLevel=0.85})

-- pattern 1
synthpattern1 = {A4,D5,A4,D5,E5,A4,D5,A4,G4}
synthdurations1 = {4,4,4,2,2,4,4,4,4}

-- 16 bars
for thisloop = 1, 2 do
  play_pattern(synthpattern1, {
    duration=synthdurations1,
    cutoff=2200,
    basscut=1.9,
    envelope=0.84,
    resonance=2.0,
    detune=0.008,
    attack=1.25,
    decay=0.50,
    sustain=0.5,
    release=0.5,
    volume=0.9})
end

-- pause 8 bars
sleep(32)

-- more distortion please! (and reapply reverb)
pop_fx("distortion")
pop_fx("reverb_massive")
push_fx("distortion", {preGain=5,postGain=0.03})
push_fx("reverb_massive", {dryLevel=0.3, wetLevel=0.85})

-- pattern 2
synthpattern2 = {{A4,A3},D5,{A4,F3},D5,E5,{A4,D3},D5,{A4,A3},{G4,D4}}
synthdurations2 = {4,4,4,2,2,4,4,4,4}

-- 16 bars
for thisloop = 1, 2 do
  -- manually trigger and sleep, as we need harmonies
  for playnotes = 1, 9 do
    play(synthpattern2[playnotes], {duration=synthdurations2[playnotes]})
    sleep(synthdurations2[playnotes])
  end
end
sleep(4)
]]),


editor("Kick", [[
-- BD
push_fx("eqthree", {lowFreq=140,highFreq=1200,lowGain=2,midGain=- 10,highGain=3})
push_fx("reverb_small", {dryLevel=0.60,wetLevel=0.10})
push_fx("compressor", {threshold=- 9, knee=5, ratio=4, attack=0.10, release=0.20})
push_fx("gainpan", {level=1.2,pan=0})

-- 16 bars
for i = 1, 16 do
  -- 1 bar BD
  drum_pattern("B--- B--- B--- B---", {
            duration=0.25,
            rate=0.75,
            level=0.6,
            B="bd_tek",
            cutoff=1400})
end
sleep(4)
]]),


editor("Perc", [[
-- percussion
push_fx("eqthree", {lowFreq=1000,highFreq=2900,lowGain=- 24,midGain=- 4,highGain=1})
push_fx("mono_delay", {delay=0.409, feedback=0.3, drylevel=0.2, wetLevel=0.04})
push_fx("ambience_medium", {wetLevel=0.4})

for i = 1, 16 do
  -- 1 bar
  drum_pattern("--t- s-tt -tt- s-tt", {
            duration=0.25,
            rate={1,0.5,1,0.25,2,0.5,1.5,1.25},
            level={0.2,0.1,0.3,0.05},
            t="hat_gem",
            s="elec_hi_snare"})
end
sleep(4)
]]),


editor("FX Perc", [[
-- percussion 2 heavy fx
push_fx("distortion", {preGain=0.8,postGain=0.08})
push_fx("reverb_medium", {dryLevel=0.3,wetLevel=0.2})
push_fx("eqthree", {lowFreq=800,highFreq=2400,lowGain=- 18,midGain=1,highGain=- 12})
   
percPatterns = {"t--- s-tt -tt- sstt","--t- s-tt --t- ----"}

-- 16 bars
for patternLoop = 1, 8 do
  for thisPattern = 1, 2 do
    drum_pattern(percPatterns[thisPattern], {
            duration=0.25,
            rate={1,0.5,1,0.25},
            level={0.4,0.3,0.6,0.2},
            t="hat_gem",
            s="elec_tick"})
  end
end
sleep(4)

]]),


editor("Random Hits", [[
-- randomised overloaded percussion hits
push_fx("distortion", {preGain=4,postGain=0.02})
push_fx("eqthree", {lowFreq=800, highFreq=2000, lowGain=- 24, midGain=0, highGain=- 6})
push_fx("reverb_large", {dryLevel=0.1, wetLevel=0.9})
push_fx("stereo_delay", {leftDelay=0.545, rightDelay=818, feedback=0.5, spread=0.3, drylevel=0.4, wetLevel=0.4})
push_fx("reverb_massive", {dryLevel=0.5, wetLevel=0.55})

sampleOptions = {"elec_tick","hat_gem","elec_filt_snare","glitch_perc4","hat_cab","glitch_perc1"}

for blockLoop = 1, 32 do
    -- init hit
  sample(sampleOptions[randi(1, 6)], {
        duration=8,
        rate=randf(0.01, 0.75),
        level=randf(0.1, 0.3),
        cutoff=randi(500, 1100)})

    -- secondary
  sleepValue = randi(0, 4)
  sleep(sleepValue)
  sample(sampleOptions[randi(1, 6)], {
        duration=randf(0.25, 4),
        rate=randf(0.1, 2.0),
        level=randf(0.2, 0.3),
        cutoff=randi(400, 3200)})

    --remaining sleep up to 8 beats
  sleep(8 - sleepValue)
end
sleep(4)
]]),


editor("Fx Crash", [[
push_fx("reverb_massive", {dryLevel=0.1, wetLevel=0.6})
sample("hat_noiz", {level=0.1,rate=0.1})
sleep(16)
]]),



markdown [[
### The Test Arrangement
Just hit *Run* to start the track. This uses the Run() command to trigger the individual code blocks at the correct time.
]],



editor("SEQUENCE", [[
-- full sequence
bar = 4

run("Random Hits")
run("Keys")
sleep(bar * 8)

run("Bass")
sleep(bar * 8)

run("FX Perc")
run("Lead")
sleep(bar * 16)

run("Fx Crash")
run("Kick")
sleep(bar * 8)

run("Perc")
sleep(bar * 8)

run("Fx Crash")
run("Kick")
sleep(bar * 16)
]]),




markdown [[
V20240922
]],



} -- end content

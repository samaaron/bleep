-- Bleep Save

title = "The Black Dog - BeatsB"
author = ""
user_id = "a16f2e75-5850-4fb7-86d2-a9cba6265aca"
description = ""
bpm = 123
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {

markdown [[
### The Black Dog - BeatsB
]],


editor("Drums", [[
-- DRUMS
push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,spread=0.7,feedback=0.2,dryLevel=0.9,wetLevel=0.2})
push_fx("eqthree", {lowFreq=300,highFreq=2800,lowGain=2,midGain=- 6,highGain=2})
push_fx("compressor", {threshold=- 12, knee=2, ratio=4, attack=0.020, release=0.150})

sample("burst_reverb", {rate=0.25,level=0.04})
randomFX = false

for sequence = 1, 12 do

  -- sequence patterns are selected at random
  --playPattern = dice(6) 

  -- play preset sequence
  playSequence = {1,1,2,2,3,4,2,2,5,6,1,1}
  playPattern = playSequence[sequence]
  
  -- randomly apply effect on this pass
  if randomFX == true then
    randomFX = false
    pop_fx()
  else 
    fxselect = dice(8)
    if fxselect == 1 then
      randomFX = true
      -- low eq
      push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=- 24,midGain=0,highGain=0})
    end
    if fxselect == 2 then
      randomFX = true
      -- high eq
      push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=0,midGain=- 1,highGain=- 24})
    end
    if fxselect == 3 then
      randomFX = true
      -- echo
      push_fx("mono_delay", {delay=0.125,feedback=0.6,dryLevel=0.6,wetLevel=0.4})
    end
    if fxselect == 4 then
      randomFX = true
      -- leslie
      push_fx("leslie", {rate=12})
    end
  end


  if playPattern == 1 then
    for i = 1, 4 do
      drum_pattern("K--K---- K--K--x-", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
    end
  end

  if playPattern == 2 then
    for i = 1, 2 do
      drum_pattern("KxxKxxxx KxxKxxDx KxxKxxxx KxxKxxSx", {
      rate={0.75,2,2,1,2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
    end
  end

  if playPattern == 3 then
    for i = 1, 8 do
      drum_pattern("xxxxxxxx", {
      rate=2,
      duration=0.25,
      x="tbd_perc_blip",
      level={0.7,0.1,0.6,0.6,0.3,0.1,0.3,0.1}})
    end
  end

  if playPattern == 4 then
    push_fx("reverb_medium", {dryLevel=0.7,wetLevel=0.2})
    for i = 1, 7 do
      drum_pattern("KxxKSxDD", {
      rate={randf(0.5,1.5),2,2,randf(0.5,1.5),2,2,randf(0.5,1.5),2},
      duration=0.25,
      K="tbd_perc_hat",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
    end
    sleep(4)
    pop_fx("reverb_medium")
  end

  if playPattern == 5 then
    for i = 1, 4 do
      drum_pattern("K-KK-xxx K-KD--xS", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
    end
  end

  if playPattern == 6 then
    for i = 1, 2 do
      drum_pattern("Dxx-xxxx -xx-xxDx Dxx-xxxx -xx-xxSx", {
      rate={randf(0.5,1.5),2,2,randf(0.25,2),2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
    end
  end

end

push_fx("reverb_massive", {dryLevel=0.3,wetLevel=0.7})
sample("elec_plip", {level=0.1,rate=0.25})
]]),


editor("Ping", [[
-- ping
use_synth("submarine")
push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,feedback=0.6,dryLevel=0.5,wetLevel=0.7})

notes = ring({C6,G4,G6,C3})
for patternLoop = 1, 4 do
  for pattern = 1, 4 do
    play(notes[pattern], {level=0.3})
    sleep(6)
  end
end
]]),


editor("DrumsLive", [[
push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,spread=0.7,feedback=0.2,dryLevel=0.9,wetLevel=0.2})
push_fx("eqthree", {lowFreq=300,highFreq=2800,lowGain=2,midGain=- 6,highGain=2})
push_fx("compressor", {threshold=- 12, knee=2, ratio=3, attack=0.020, release=0.2})

sample("burst_reverb", {rate=0.25,level=0.04})
randomFX = false

-- NO "FOR" ACTION, USE NEW LOOP CONTROL
-- enter pattern and fx code, then trigger

-- select options
playPattern = 1 -- BD=1,2,5,7 break=3,4,6
fxSelect = 0 -- 0 or 1-4


-- apply fx
if fxSelect == 1 then
    -- low eq cut
  push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=- 24,midGain=0,highGain=0})
end
if fxSelect == 2 then
    -- high eq cut
  push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=0,midGain=- 1,highGain=- 24})
end
if fxSelect == 3 then
    -- echo
  push_fx("mono_delay", {delay=0.125,feedback=0.6,dryLevel=0.6,wetLevel=0.4})
end
if fxSelect == 4 then
    -- leslie
  push_fx("leslie", {rate=12})
end

-- play pattern
if playPattern == 1 then
  for i = 1, 2 do
    drum_pattern("K--K---- K--K--x-", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  end
end
if playPattern == 2 then
  drum_pattern("KxxKxxxx KxxKxxDx KxxKxxxx KxxKxxSx", {
      rate={0.75,2,2,1,2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
end
if playPattern == 3 then
  for i = 1, 8 do
    drum_pattern("xxxxxxxx", {
      rate=2,
      duration=0.25,
      x="tbd_perc_blip",
      level={0.7,0.1,0.6,0.6,0.3,0.1,0.3,0.1}})
  end
end
if playPattern == 4 then
  push_fx("reverb_medium", {dryLevel=0.7,wetLevel=0.2})
  for i = 1, 7 do
    drum_pattern("KxxKSxDD", {
      rate={randf(0.5,1.5),2,2,randf(0.5,1.5),2,2,randf(0.5,1.5),2},
      duration=0.25,
      K="tbd_perc_hat",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  end
  sleep(4)
  pop_fx("reverb_medium")
end
if playPattern == 5 then
  for i = 1, 4 do
    drum_pattern("K-KK-xxx K-KD--xS", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  end
end
if playPattern == 6 then
  for i = 1, 2 do
    drum_pattern("Dxx-xxxx -xx-xxDx Dxx-xxxx -xx-xxSx", {
      rate={randf(0.5,1.5),2,2,randf(0.25,2),2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  end
end
if playPattern == 7 then
  drum_pattern("KxKKxxSx KKxKxKDx KxKKxKDx KxDKKKSx", {
      rate={0.75,2,2,1,2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
end
]]),


editor(" Plip Crash", [[
push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=- 24,midGain=0,highGain=0})
push_fx("reverb_massive", {dryLevel=0.3,wetLevel=0.7})
sample("elec_plip", {level=0.2,rate=0.25})]]),


} -- end content

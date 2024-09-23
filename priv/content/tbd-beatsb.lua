-- Bleep Save

title = "The Black Dog - BeatsB"
author = ""
user_id = "f96e4d78-89cc-4e7d-9244-dd73dade2416"
description = ""
bpm = 123
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {

markdown [[
# The Black Dog - BeatsB
]],


markdown [[
"This is an early experiment for running a series of drum patterns and effects, using just a couple of variables to make all the changes." - tBd
]],


markdown [[
### Drums - 1 Bar
Enable "Loop" mode and hit Cue to get started. Change the variables to select different drum patterns and effects, then hit Cue again to hear the changes. The new version will replace the previous loop.
]],


editor("D 1Bar", [[
-- NO "FOR" ACTION, USE NEW LOOP CONTROL
-- enter pattern and fx code, then trigger

push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,spread=0.5,feedback=0.2,dryLevel=0.9,wetLevel=0.15})
push_fx("reverb_small", {dryLevel=0.9,wetLevel=0.15})
push_fx("eqthree", {lowFreq=300,highFreq=2800,lowGain=2,midGain=- 6,highGain=2})
push_fx("compressor", {threshold=- 12, knee=2, ratio=4, attack=0.012, release=0.15})
--sample("burst_reverb", {rate=0.25,level=0.04})

-- select options
playPattern = 1 -- BD=1,2,5,7 breakdown=3,4,6
fxSelect = 0 -- 0 for no fx, or 1-4


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
  --for i = 1, 2 do
  drum_pattern("K--K ---- K--K --x-", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  --end
end
if playPattern == 2 then
  drum_pattern("KxxK xxxx KxxK xxDx", {
      rate={0.75,2,2,1,1.5,2,2,1},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.5,0.6}})
end
if playPattern == 3 then
  for i = 1, 2 do
    drum_pattern("xxxx xxxx", {
        rate=2,
        duration=0.25,
        x="tbd_perc_blip",
        level={0.7,0.1,0.6,0.6,0.3,0.1,0.3,0.1}})
  end
end
if playPattern == 4 then
  push_fx("reverb_medium", {dryLevel=0.6,wetLevel=0.25})
  for i = 1, 2 do
    drum_pattern("KxxK SxDD", {
      rate={randf(0.5,1.5),2,2,randf(0.5,1.5),2,2,randf(0.5,1.5),2},
      duration=0.25,
      K="tbd_perc_hat",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  end
  --sleep(4)
  pop_fx("reverb_medium")
end
if playPattern == 5 then
  --for i = 1, 4 do
  drum_pattern("K-KK -xxx K-KD --xS", {
      rate={0.75,2,2,1,2,2,randf(0.25,1.0),2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  --end
end
if playPattern == 6 then
  --for i = 1, 2 do
  drum_pattern("Dxx- xxxx -xx- xxDx", {
      rate={randf(0.5,1.5),2,2,randf(0.25,2),2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.95,0.1,0.7,0.6,0.3,0.1,0.09,0.1}})
  --end
end
if playPattern == 7 then
  drum_pattern("KxKK xxSx KKxK xKDx", {
      rate={0.75,2,2,1,2,2,0.5,2},
      duration=0.25,
      K="bd_gas",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.90,0.1,0.6,0.5,0.3,0.1,0.09,0.1}})
end

]]),


markdown [[
### Drums - 1 Bar v2
Same concept as before, just with new patterns.
]],


editor("D 1Bar 2", [[
-- NO "FOR" ACTION, USE NEW LOOP CONTROL
-- enter pattern and fx code, then trigger
push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,spread=0.5,feedback=0.3,dryLevel=0.9,wetLevel=0.10})
push_fx("reverb_small", {dryLevel=0.9,wetLevel=0.2})
push_fx("eqthree", {lowFreq=300,highFreq=2800,lowGain=- 3,midGain=- 2,highGain=2})
push_fx("compressor", {threshold=- 12, knee=2, ratio=4, attack=0.012, release=0.15})

-- select options
playPattern = 1 -- newBD=1,2,3,4 break=
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
  drum_pattern("KxKK xxSx KKxK xKDx", {
      rate={0.75,2,2,1,2,2,0.5,2},
      duration=0.25,
      K="bd_pure",
      x="tbd_perc_blip",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.90,0.1,0.6,0.5,0.3,0.1,0.09,0.1}})
end
if playPattern == 2 then
  drum_pattern("K-KK x--- KKxK DKx-", {
      rate={0.75,2,2,1,2,2,2,2},
      duration=0.25,
      K="bd_pure",
      x="hat_star",
      D="tbd_perc_tap_2",
      S="tbd_perc_tap_1",
      level={0.90,0.1,0.6,0.5,0.3,0.1,0.09,0.1}})
end
if playPattern == 3 then
  drum_pattern("K-KK xJxx KKxK SKx-", {
      rate={0.75,2,2,1,2,2,2,2},
      duration=0.25,
      K="bd_pure",
      x="hat_star",
      D="tbd_perc_tap_2",
      J="elec_blip2",
      S="hat_sci",
      level={0.90,0.1,0.6,0.5,0.3,0.1,0.09,0.1}})
end
if playPattern == 4 then
  drum_pattern("K--- xJ-x --x- --x-", {
      rate={0.75,2,2,2,2,2,1,2},
      duration=0.25,
      K="bd_pure",
      x="hat_star",
      D="tbd_perc_tap_2",
      J="elec_blip2",
      S="tbd_perc_tap_1",
      level={0.90,0.1,0.6,0.5,0.3,0.1,0.09,0.1}})
end]]),


markdown [[
### 4/4 Time Kick
If your patterns need a little extra, drop in a standard 4/4 time kick drum to underpin the mix. Remember to enable "Loop" mode!
]],


editor("4/4 Kick", [[
-- 4/4 Kick
drum_pattern("KKKK", {
      rate=0.75,
      duration=1,
      K="bd_gas",
      level=0.99})
]]),


markdown [[
### Simple Crash Effect
Just because we can.
]],


editor("Crash FX", [[
push_fx("eqthree", {lowFreq=180,highFreq=2800,lowGain=- 24,midGain=0,highGain=0})
push_fx("reverb_massive", {dryLevel=0.3,wetLevel=0.7})
sample("elec_plip", {level=0.2,rate=0.25})]]),


markdown [[
### Drums - Randomised
An alternative version, where the pattern and effect selections are both chosen using random values. No need to use "Loop" mode as it's intended to run for a set number of iterations.
]],


editor("D Random", [[
-- DRUMS
push_fx("stereo_delay", {leftDelay=0.375,rightDelay=0.750,spread=0.7,feedback=0.2,dryLevel=0.9,wetLevel=0.2})
push_fx("eqthree", {lowFreq=300,highFreq=2800,lowGain=2,midGain=- 6,highGain=2})
push_fx("compressor", {threshold=- 12, knee=2, ratio=4, attack=0.020, release=0.150})

sample("burst_reverb", {rate=0.25,level=0.04})
randomFX = false

for sequence = 1, 16 do

  -- sequence patterns are selected at random
  playPattern = dice(6)
  
  -- if effect was previously enabled, reset for this pass
  if randomFX == true then
    randomFX = false
    pop_fx()
  else 
    -- randomly apply effect on this pass
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


markdown [[
v20240922
]],


} -- end content

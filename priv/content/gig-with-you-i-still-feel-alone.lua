-- Bleep Save

title = "The Black Dog - With You I Stll Feel Alone"
author = ""
user_id = "2e295afb-48cb-41b6-930c-ade68ebf017e"
description = ""
bpm = 130
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {

markdown [[
### The Black Dog - With You I Stll Feel Alone
]],


editor("1. FULL SEQ", [[
-- FULL Sequence
push_fx("reverb_small", {wetLevel=0.32})
push_fx("eqthree", {lowFreq=140,highFreq=3500,lowGain=1.4,midGain=- 5,highGain=2})
push_fx("compressor", {threshold=- 14, knee=8, ratio=1.6, attack=0.012, release=0.230})
push_fx("gainpan", {level=1.1,pan=0})

-- FX hit start
sample("burst_reverb", {
    duration=4,
    rate=randf(0.1, 1.5),
    level=randf(0.2, 0.4),
    cutoff=randi(800, 5000)})

-- "bars" is the bar count

-- initial BD
for bars = 1, 4 do
  drum_pattern("B--- B--- B--B ----", {
            duration=0.25,
            cutoff=12000,
            rate=0.8,
            level={0.85,0,0,0,0.7,0,0.4,0,0.8,0,0,0.6,0,0,0,0},
            B="bd_sone"})
end


-- MAIN LOOP: BD perc + variations
for bars = 1, 80 do
    
  -- add fx loop 1 bar
  if (bars >= 9 and bars <= 16) or (bars >= 33 and bars <= 40) or (bars >= 67 and bars <= 80) then
    sample("tbd_fxbed_loop", {
            level=0.1,
            duration=1.6,
            loop=false})
  end

  -- burst fx
  if bars == 1 or bars == 15 or bars == 17 or bars == 29 or bars == 33 or bars == 49 or bars == 64 or bars == 65 or bars == 69 or bars == 73 then
    sample("burst_reverb", {
      duration=4,
      rate=randf(0.1, 1.5),
      level=randf(0.2, 0.4),
      cutoff=randi(800, 5000)})
  end

    -- play pads
    -- pad1 8bar
  if bars == 17 or bars == 33 or bars == 49 or bars == 65 then
    grains("tbd_pad_1", {
            level=0.3,
            attack=1.5,
            decay=2,
            sustain=0.8,
            release=3,
            duration=14.7,
            density=10,
            index=0.5,
            size=0.9,
            shape=0.5,
            pan_var=0.1,
            index_var =0.01,
            time_var =0.01,})
  end
    --pad2 4bar
  if bars == 25 or bars == 41 or bars == 57 or bars == 73 then
    grains("tbd_pad_2", {
            level=0.3,
            attack=1.5,
            decay=2,
            sustain=0.8,
            release=3,
            duration=7.4,
            density=10,
            index=0.5,
            size=0.9,
            shape=0.5,
            pan_var=0.1,
            index_var =0.01,
            time_var =0.01,})
  end 
  --pad3 2bar
  if bars == 29 or bars == 45 or bars == 61 or bars == 77 then
    grains("tbd_pad_3", {
            level=0.4,
            attack=1.5,
            decay=2,
            sustain=0.8,
            release=3,
            duration=3.7,
            density=10,
            index=0.5,
            size=0.9,
            shape=0.5,
            pan_var=0.1,
            index_var =0.01,
            time_var =0.01,})
  end
  --pad4 2bar
  if bars == 31 or bars == 47 or bars == 63 or bars == 79 then
    grains("tbd_pad_4", {
            level=0.3,
            attack=1.5,
            decay=2,
            sustain=0.8,
            release=3,
            duration=3.7,
            density=10,
            index=0.5,
            size=0.9,
            shape=0.5,
            pan_var=0.1,
            index_var =0.01,
            time_var =0.01,})
  end 


  -- voc tone
  if bars == 53 or bars == 61 then
    sample("tbd_voctone", {
      level=0.4,
      duration=8,
      rate=1,
      loop=false})
  end

  if bars == 63 then
    sample("tbd_voctone", {
      level=0.3,
      duration=4,
      rate=0.666,
      loop=false})
  end

  --mute drums for break
  if bars < 49 or bars > 64 then
    -- bd and perc
    drum_pattern("BtbT Bthb BtTB TtTb", {
              duration=0.25,
              cutoff=12000,
              rate={0.85,1,1,1,0.7,1,1,1,0.8,1,1,0.6,1,1,1,1},
              level={0.9,0.4,0.6,0.4,0.8,0.4,0.6,0.4,0.9,0.4,0.6,0.7,0.8,0.4,0.6,0.4},
              B="bd_sone",
              b="tbd_perc_blip",
              h="tbd_perc_hat",
              t="tbd_perc_tap_1",
              T="tbd_perc_tap_2"})
  
  else
    -- do hi keys and control sleeps
    if bars == 49 or bars == 50 or bars == 57 then
      if bars == 49 then
        sample("tbd_highkey_c4", {
          level=0.35,
          duration=4,
          rate=0.5,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.16,
          duration=4,
          rate=0.5,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.4,
          duration=4,
          rate=0.75,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.16,
          duration=4,
          rate=0.75,
          loop=false})
        sleep(0.5)        
        sample("tbd_highkey_c4", {
          level=0.4,
          duration=4,
          rate=1,
          loop=false})
        sleep(0.5)
      end

      --just echos
      if bars == 50 then
        sleep(0.5)
        sample("tbd_highkey_c4", {
          level=0.16,
          duration=4,
          rate=1,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.12,
          duration=4,
          rate=1,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.08,
          duration=4,
          rate=1,
          loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
          level=0.04,
          duration=4,
          rate=1,
          loop=false})
        sleep(0.5)      
      end

      -- alternative part
      if bars == 57 then       
        sample("tbd_highkey_c4", {
            level=0.4,
            duration=4,
            rate=1,
            loop=false})
        sleep(2)
        sample("tbd_highkey_c4", {
            level=0.4,
            duration=4,
            rate=0.75,
            loop=false})
        sleep(0.5)
        sample("tbd_highkey_c4", {
            level=0.4,
            duration=8,
            rate=1,
            loop=false})
        sleep(1)
        sample("tbd_highkey_c4", {
            level=0.16,
            duration=8,
            rate=1,
            loop=false})
        sleep(0.5)
      end
    else
      sleep(4)
    end
  end

end -- end for loop



-- BD outro
for bars = 1, 8 do

  if bars == 1 or bars == 3 then
  -- FX
    sample("tbd_fxbed_loop", {level=0.1,loop=false})
  end

  if bars == 5 or bars == 8 then
  -- FX hit
    sample("burst_reverb", {
    duration=4,
    rate=randf(0.1, 1.5),
    level=randf(0.2, 0.4),
    cutoff=randi(800, 5000)})
  end

  drum_pattern("B--- B--- B--B ----", {
            duration=0.25,
            cutoff=12000,
            rate=0.8,
            level={0.8,0,0,0,0.8,0,0.4,0,0.8,0,0,0.6,0,0,0,0},
            B="bd_sone"})
end

-- FX hit
sample("burst_reverb", {
  duration=4,
  rate=randf(0.1, 1.5),
  level=randf(0.2, 0.4),
  cutoff=randi(800, 5000)})

sleep(16)
--END]]),


editor("2. Kick & FX", [[
-- BD
--push_fx("mono_delay", {delay=0.25,feedback=0.3,wetLevel=0.3})
push_fx("reverb_small", {dryLevel=0.75,wetLevel=0.3})
push_fx("eqthree", {lowFreq=120,highFreq=1900,lowGain=2,midGain=- 6,highGain=2})
push_fx("compressor", {threshold=- 5, knee=4, ratio=4, attack=0.020, release=0.2})

if dice(10) < 3 then
  sample("burst_reverb", {
    rate=randf(0.1, 1.5),
    level=randf(0.1, 0.3),
    cutoff=randi(800, 5000)})
end
drum_pattern("B--- B--- B--B ----", {
          duration=0.25,
          cutoff=3200,
          rate=0.8,
          level={0.8,0,0,0,0.6,0,0.4,0,0.7,0,0,0.5,0,0,0,0},
          B="bd_sone"})
]]),


editor("3. Perc New", [[
-- hats
push_fx("deep_phaser", {wetLevel=0.9})
push_fx("mono_delay", {delay=0.25,feedback=0.2,wetLevel=0.3})
push_fx("reverb_medium", {wetLevel=0.7})
push_fx("compressor", {threshold=- 3, knee=3, ratio=9, attack=0.020, release=0.1})

drum_pattern("--tt -t-t --tt --tt", {
          duration=0.25,
          cutoff=12000,
          rate=2,
          level={randf(0.3,0.5),randf(0.2,0.4),randf(0.3,0.6),randf(0.2,0.4)},
          t="elec_plip"})

]]),


editor("4. Perc", [[
-- perc loop
push_fx("reverb_medium", {wetLevel=0.1})
drum_pattern("htbT bthb btTh TtTb", {
            duration=0.25,
            cutoff=12000,
            rate=1,
            level={randf(0.4,0.6),randf(0.2,0.4),randf(0.3,0.6),randf(0.2,0.4)},
            b="tbd_perc_blip",
            h="tbd_perc_hat",
            t="tbd_perc_tap_1",
            T="tbd_perc_tap_2"})

]]),


editor("5. FX Bed", [[
-- FX Bed
push_fx("reverb_large", {wetLevel=0.7})

sample("tbd_fxbed_loop", {
  level=0.2,
  loop=false})
sleep(16)
]]),


editor("6. Pad", [[
-- Sustained Pad
--push_fx("stereo_delay", {leftDelay=0.346,rightDelay=0.231,feedback=0.3,wetLevel=0.3})
push_fx("reverb_large", {dryLevel=0.4,wetLevel=0.6})
push_fx("compressor", {threshold=- 6, knee=8, ratio=3, attack=0.10, release=0.2})

padSamples = {"tbd_pad_1","tbd_pad_2","tbd_pad_3","tbd_pad_4"}
padDurations = {14.5,7.3,3.7,3.7} -- measured in seconds
padSleeps = {32,16,8,8} -- measured in beats!

for sampleSelect = 1, 4 do
  grains(padSamples[sampleSelect], {
          level=0.4,
          attack=2,
          decay=2,
          sustain=0.8,
          release=3,
          duration=padDurations[sampleSelect],
          density=10,
          index=0.5,
          size=0.9,
          shape=0.5,
          pan_var=0.1,
          index_var =0.01,
          time_var =0.01,})
  sleep(padSleeps[sampleSelect])
end
]]),


editor("7. High Keys", [[
-- high key sample
push_fx("stereo_delay", {leftDelay=0.346,rightDelay=0.231,feedback=0.8,wetLevel=0.38})
push_fx("reverb_large", {drylevel=0.5,wetLevel=0.7})
push_fx("eqthree", {
   lowFreq=900,
   highFreq=2400,
   lowGain=- 10,
   midGain=0,
   highGain=1})

for patternloop = 1, 2 do
  sample("tbd_highkey_c4", {
    level=0.4,
    duration=4,
    rate=0.5,
    loop=false})
  sleep(2)
  sample("tbd_highkey_c4", {
    level=0.4,
    duration=4,
    rate=0.75,
    loop=false})
  sleep(1.5)
  sample("tbd_highkey_c4", {
    level=0.4,
    duration=12,
    rate=1,
    loop=false})
  sleep(12.5)
end

-- alternative for final third pass
sample("tbd_highkey_c4", {
    level=0.4,
    duration=4,
    rate=1,
    loop=false})
sleep(2)
sample("tbd_highkey_c4", {
    level=0.4,
    duration=4,
    rate=0.75,
    loop=false})
sleep(0.5)
sample("tbd_highkey_c4", {
    level=0.4,
    duration=12,
    rate=1,
    loop=false})
--sleep(12.5)

sleep(16)
]]),


editor("8. Voc Tone", [[
-- Voc Tone
push_fx("reverb_large", {drylevel=0.3,wetLevel=0.9})

sample("tbd_voctone", {
    level=0.4,
    duration=8,
    rate=1,
    loop=false})
sleep(16)
sample("tbd_voctone", {
    level=0.4,
    duration=4,
    rate=1,
    loop=false})
sleep(8)
sample("tbd_voctone", {
    level=0.3,
    duration=4,
    rate=0.666,
    loop=false})
--sleep(8)

sleep(16)
]]),


editor("9. Burst FX", [[
-- FX
push_fx("reverb_massive", {dryLevel=0.2,wetLevel=0.6})

sleepInit = randi(0, 4)
sleep(sleepInit)
sample("burst_reverb", {
  duration=4,
  rate=randf(0.1, 1.5),
  level=randf(0.2, 0.5),
  cutoff=randi(800, 5000)})
sleep(8 - sleepInit)
]]),


} -- end content

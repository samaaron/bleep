-- Bleep Save

title = "The Black Dog - Drone & Arp"
author = ""
user_id = "2e295afb-48cb-41b6-930c-ade68ebf017e"
description = ""
bpm = 60
quantum = 4

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {

markdown [[
### The Black Dog - Drone & Arp
]],


editor("Drone", [[
-- drone for adjusting across multiple triggers
use_synth("chiral")
push_fx("reverb_large", {wetLevel=0.7})
push_fx("chorus", {rate=0.3,spread=0.7,depth=0.2,dryLevel=0.4,wetLevel=0.6})
push_fx("stereo_delay", {leftDelay=0.540, rightDelay=0.550, spread=0.6, feedback=0.7, drylevel=0.45, wetLevel=0.6})

-- edit these...
theNote = A0 -- As,F,C,Gs
theCutoff = 1000 -- 100-8000
theResonance = 2.5 -- 0-20
theNoise = 0.05 -- 0-1
theGain = 0.15 -- 0.01-1
theSymmetry = - 0.5 -- -1-1

-- now play
play(theNote, {
    duration=32,
    cutoff=randi(theCutoff - 200, theCutoff + 200),
    resonance=theResonance,
    volume=randf(0.6, 0.8),
    noise=theNoise,
    gain=theGain,
    symmetry=theSymmetry,
    symmetry_mod=0.4,
    amp_level=0.36,
    amp_rate=2,
    lfo_rate=0.61,
    attack=2,
    decay=4.0,
    sustain=0.8,
    release=8})

sleep(40)

]]),


editor("Arpeggio", [[
-- arpeggio to play as round-robin, adjust parameters and retrigger 
use_synth("rolandtb")
push_fx("reverb_large", {wetLevel=0.6})
push_fx("chorus", {rate=0.3,spread=0.7,depth=0.2,dryLevel=0.4,wetLevel=0.6})
push_fx("stereo_delay", {leftDelay=0.540, rightDelay=0.550, spread=0.6, feedback=0.7, drylevel=0.45, wetLevel=0.6})

notes = ring({As4,F4,C5,F4,As4,C5,Gs4,C4,C3,C3,Gs3,As3})
theRepeats = 8

-- parameter to change and re-cue
theDuration = 1 -- 1 0.5 0.25
theTranspose = 0  -- 0 12 7
theCutoff = 1500 -- 0-10000

theResonance = 9.0 -- 0-25
theEnvelope = 0.82 -- 0-0.95

theMirror = 0 -- 0 or 1
theShuffle = 0 -- 0 or 1
theAlternate = 0 -- 0 or a multiplier


-- apply all parameters
thePattern = notes:add(theTranspose)

if theMirror > 0 then
  thePattern = thePattern:mirror()
end

if theShuffle > 0 then
  thePattern = thePattern:shuffle()
end

if theAlternate > 0 then
  thePattern = thePattern:alternate(theAlternate)
end

theVolume = 0.05

for patternLoop = 1, theRepeats do

    -- adjust volume and cutoff through the pattern
  toCheck = theRepeats / 2
  if patternLoop <= toCheck then
    theVolume = theVolume + 0.15
    theCutoff = theCutoff + 350
  end
  if patternLoop > toCheck then
    theVolume = theVolume - 0.15
    theCutoff = theCutoff - 350
  end
    
  play_pattern(thePattern, {
        duration=theDuration,
        cutoff=randi(theCutoff - 100, theCutoff + 100),
        resonance=theResonance,
        envmod =theEnvelope,
        volume=theVolume,
        attack=0.02,
        decay=0.09,
        sustain=0.3,
        release=1.0})
end]]),


editor("BG Noise", [[
-- background fx
push_fx("reverb_massive", {dryLevel=0.4,wetLevel=0.9})
push_fx("compressor", {threshold=- 12, knee=8, ratio=1.6, attack=0.012, release=0.230})
push_fx("eqthree", {lowFreq=140,highFreq=2400,lowGain=- 18,midGain=0,highGain=0})
-- push_fx("gainpan", {level=0.2,pan=- 0.2})

grains("vinyl_hiss", {
        rate=0.2,
        level=0.75,
        density=8,
        index=0.0,
        size=0.4,
        shape=0.2,
        pan_var=0.2,
        index_var =0.01,
        time_var =0.02,
        attack=5,
        release=5,
        duration=20})
sleep(18)
grains("vinyl_hiss", {
        rate=0.1,
        level=0.75,
        density=12,
        index=0.1,
        size=0.1,
        shape=0.2,
        pan_var=0.2,
        index_var =0.01,
        time_var =0.02,
        attack=5,
        release=5,
        duration=20})
sleep(20)]]),


editor("FX Hit", [[
-- background fx hit
push_fx("reverb_massive", {dryLevel=0.4,wetLevel=0.9})
push_fx("compressor", {threshold=- 7, knee=8, ratio=2, attack=0.012, release=0.230})
push_fx("eqthree", {lowFreq=140,highFreq=2400,lowGain=- 18,midGain=0,highGain=0})

sample("burst_reverb", {
    duration=8,
    rate=randf(0.20, 0.5),
    level=0.1})
]]),


editor("", [[
-- spare

]]),


} -- end content

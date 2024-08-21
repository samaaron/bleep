-- Bleep Save

title = ""
author = ""
user_id = "bee70b1d-232c-48e1-9468-fb3fa908f8e8"
description = ""
bpm = 120
quantum = 4

init = [[
-- this code is automatically
-- inserted before every run
]]

content = {

markdown [[
## STEM Workshop August 2024
]],


editor("bass drum", [[
for i = 1, 1000 do
  sample("bd_sone", {cutoff=500})
  sleep(1)
end]]),


editor("snare hats", [[
for i = 1, 1000 do
  sleep(0.5)
  sample("hat_gnu")
  sleep(0.5)
end
]]),


editor("odd hats", [[
for i = 1, 2000 do
  if (dice(3) == 1) then
    sample("hat_tap", {level=0.7,rate=1.5,pan=0.5})
  end
  sleep(0.25)
end]]),


editor("quiet hats", [[
for i = 1, 1000 do
  sample("hat_tap", {level=0.6,pan=- 0.5})
  sleep(0.25)
  for j = 1, 3 do
    sample("hat_tap", {level=0.4,pan=- 0.5})
    sleep(0.25)
  end
end]]),


editor("rumble", [[
push_fx("stereo_delay", {wetLevel=0.3,dryLevel=1})
use_synth("thickbass")
for i = 1, 1000 do
  sleep(0.5)
  play(D1, {duration=0.45, cutoff=300,level=0.8})
  sleep(0.5)
end]]),


editor("arpeggio", [[
notes = ring({D3,F3,D4,F4,D5})
push_fx("stereo_delay", {wetLevel=0.1})
use_synth("rolandtb")
for i = 1, 100 do
  play_pattern(notes:pick(16), {cutoff=1200, env_mod=0.7,duration=0.25,gate=0.4})
end
]]),


editor("chords", [[
push_fx("stereo_delay", {wetLevel=0.4,dryLevel=1})
push_fx("reverb_massive", {wetLevel=0.4,dryLevel=1})
use_synth("fairvoice")
play(D4, {duration=3})
play(F4, {duration=3})
sleep(8)
play(D4, {duration=3})
play(E4, {duration=3})
]]),


editor("bassline", [[
push_fx("stereo_delay", {wetLevel=0.3,dryLevel=1})
c = 3000
use_synth("rolandtb")
for i = 1, 100 do
  play_pattern({D2,D2,D2,D2,Ds2,D2,D2}, {
    env_mod=0.7,
    level=0.6,
    resonance=10,
    cutoff=c,
    duration={0.25,0.25,0.25,0.25,0.5,0.25,0.25},
    gate=0.3})
  sleep(0.25)
  play_pattern({D2,Ds2,D2,Ds2,D2,F1,D3}, {
    env_mod=0.7,
    level=0.6,
    resonance=10,
    cutoff=c,
    duration={0.25},
    gate=0.3})
end
]]),


editor("tom toms", [[
for i = 1, 16 do
  d = dice(4)
  if (d == 1) then
    sample("drum_tom_lo_hard", {rate=0.8,level=0.3,pan=- 0.5})
  end
  if (d == 2) then
    sample("drum_tom_mid_hard", {rate=0.8,level=0.3,pan=0.5})
  end
  sleep(0.25)
end]]),


editor("atmospherics", [[
use_synth("highnoise")
push_fx("reverb_large", {wetLevel=0.4,dryLevel=1})
cut = rand_ring(32, 500, 10000):sort():reverse()
for i = 1, 32 do
  dur = math.random(1, 4) * 0.25
  play(C4, {
            level=0.3,
            volume=0.4,
            duration=dur,
        cutoff=cut[i]})
  sleep(dur)
end
]]),


editor("warning overload", [[
push_fx("reverb_large", {wetLevel=0.3})
sample("robot_warning")]]),


editor("bassline engaged", [[
push_fx("reverb_large", {wetLevel=0.3})
sample("robot_bassline")]]),


editor("techno protocol", [[
push_fx("reverb_large", {wetLevel=0.3})
sample("robot_protocol")]]),


editor("drop incoming", [[
push_fx("reverb_large", {wetLevel=0.3})
sample("robot_drop")]]),


} -- end content

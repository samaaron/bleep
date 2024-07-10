bpm = 120

content = {

markdown [[
## Latest changes 10/7/2024
]],

markdown [[
* New audio engine integrated into bleep
* The play command now takes a single note or a list of notes to play together (in other words, a chord)
* Granular synthesis added - see manual page [here](https://bleep.sheffield.ac.uk/artist/grains)
]],

editor [[
-- demo of the new play command
use_synth("elpiano")
play(C4,{level=0.3,duration=1}) -- single note
sleep(4)
play({C4,E4,G4},{level=0.3,duration=1}) -- chord
sleep(4)
for i = 0, 8 do
  play({C4-i,E4-i,G4-i},{level=0.3,duration=0.5}) -- notes can be variables too
  sleep(0.5)
end
]],

editor [[
-- another demo of the play command
notes = scale("harmonic_minor", D3, 2)
set_seed(142)
use_synth("voxhumana")
push_fx("stereo_delay", {wetLevel=0.1,leftDelay=0.8,rightDelay=0.6,feedback=0.4})
push_fx("reverb_massive", {wetLevel=0.4,dryLevel=1})
for i = 1, 8 do
  p1 = notes[randi(1, 16)]
  p2 = notes[randi(1, 16)]
  p3 = notes[randi(1, 16)]
  play({p1,p2,p3}, {level=0.3,duration=1}) -- random triad
  sleep(8)
end
]],

editor [[
]],

editor [[
]],

editor [[
]],

editor [[
]]

}
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
bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Making a bass line
]],

markdown [[
You can make a bass line using **play** and **sleep**, using arrays to hold the note values and sleep times.
]],

editor("bassline one",[[
use_synth("rolandtb")
notes = {A1,A1,A1,A1,A1,A2,A1}
sleeps = {0.5,1,1.5,1,0.5,1,2.5}
for i = 1, 7 do
  play(notes[i], {duration=0.25})
  sleep(sleeps[i])
end
]]),

markdown [[
An array is just a list, so notes[i] means the ith note in the list. The first note is i[1], the second note is notes[2] and so on.
]],

markdown [[
The **rolandtb** synth simulates the sound of the classic Roland TB-303 Bassline synth. Play with the **cutoff**, **resonance** and **env_mod** (envelope modulation) controls.
]],

editor("bassline two",[[
use_synth("rolandtb")
notes = {A1,A1,A1,A1,A1,A2,A1}
sleeps = {0.5,1,1.5,1,0.5,1,2.5}
for i = 1, 7 do
  play(notes[i],{duration=0.25,
       cutoff=700,env_mod=0.7,resonance=12})
  sleep(sleeps[i])
end
]]),

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
The interplay of the bass line and the drums is very important. Cue this drum loop in another box and listen to it with the bassline above. Now remove the sleep command and hear the difference.
]],

editor("drums", [[
sleep(0.5)
for i = 1, 6 do
  drum_pattern("B--- B--- B--- B---", {
     duration=0.25,
     cutoff=700,
     level=0.3,
     B="bd_sone"})
end
]]),

markdown [[
Sub-bass can be important to help set the groove and underpin the kick drum. But don't play it fast, speakers can't cope!
]],

editor("subbass",[[
sleep(0.5)
use_synth("subbass")
for i = 1, 6 do
  play(A0, {duration=0.5,level=1.5})
  sleep(4)
end
]]),


}
bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Playing synths
]],

markdown [[
Play a note by selecting a synth with **use_synth** and using the **play** command with the note name.
]],

editor [[
use_synth("rolandtb")
play(C4)
]],

markdown [[
Note names are C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B where "s" means "sharp". Notes range from A0 (very low) to G9 (very high).
]],

editor [[
use_synth("thickbass")
play(Ds2)
]],

markdown [[
Several play commands will play the notes together to make a chord.
]],

editor [[
use_synth("junopad")
play(C4)
play(E4)
play(G4)
]],

markdown [[
To play a sequence of notes, add **sleep** commands to create a pause between them. Here we pause for 1 beat after each note.
]],

editor [[
use_synth("softlead")
play(C4)
sleep(1)
play(E4)
sleep(1)
play(G4)
]],

markdown [[
You can vary the sleep times and note durations to get the tune you want.
]],

editor [[
use_synth("bansuri")
play(C4,{duration=0.2})
sleep(0.5)
play(E4,{duration=0.2})
sleep(0.75)
play(G4,{duration=1.5})
]],

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
Like instruments in a traditional band, choose a selection of synths that have different sound qualities and occupy different pitch ranges. 
For example, contrast a bass synth with a sharper, higher sound.
]],

editor [[
use_synth("thickbass")
play(D2, {duration=2})
use_synth("rolandtb", {env_mod=0.7})
play(D5, {duration=0.1})
sleep(0.25)
play(Ds5, {duration=0.1})
sleep(0.25)
play(D5, {duration=0.1})
]],

}
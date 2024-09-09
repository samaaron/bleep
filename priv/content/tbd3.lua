bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Using effects
]],

markdown [[
Apply an audio effect by using the **push_fx** command. Reverberation (**reverb**) adds a sense of space.
]],

editor [[
push_fx("reverb_large",{wetLevel=0.8})
sample("tbd_perc_tap_1")
]],

markdown [[
Change the **wetLevel** to between 0 and 1 to vary the amount of effect. This example used a **delay** effect.
]],

editor [[
push_fx("stereo_delay",{wetLevel=0.4})
sample("tbd_perc_tap_2")
]],

markdown [[
Use **chorus** to thicken a sound.
]],

editor [[
push_fx("chorus")
use_synth("rolandtb")
play(C2, {duration=2})
]],

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
Lines that start with `--` are **comments**, which are ignored. You can add and remove comments to quickly turn effects on and off.
]],

editor [[
--push_fx("stereo_delay", {wetLevel=0.5})
use_synth("breton")
play(Cs6)
sleep(1)
play(As5)
sleep(0.5)
play(Fs5)
]],

markdown [[
Use a **phaser** effect to add a sense of movement to a sound.
]],

editor [[
push_fx("deep_phaser")
use_synth("synthstrings")
play(Ds4, {duration=4})
play(C3, {duration=4})
play(C2, {duration=4})
]],

markdown [[
Create huge washes of sound by **chaining** effects together, such as a delay into a reverb, or a reverb into another reverb!
]],

editor [[
push_fx("stereo_delay", { feedback=0.6, wetLevel=0.8})
push_fx("reverb_massive", {wetLevel=0.8})
use_synth("submarine")
play(C6, {level=0.8})
]],

}
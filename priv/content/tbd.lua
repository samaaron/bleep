bpm = 120

content = {

markdown [[
## Analogue lead
[Click here for documentation](https://github.com/guyjbrown/bleepmanual/wiki/analoguelead)
]],

editor [[
sample("analog_lead_d4")
sleep(5)
sample("analog_lead_d2")
sleep(6)
push_fx("roland_chorus", {wetLevel=1,dryLevel=0})
push_fx("reverb_large", {wetLevel=0.4})
use_synth("analoguelead")
play(D4, {duration=2, level=0.7})
sleep(5)
play(D2, {duration=2, level=0.7})

]],

markdown [[
## Synth strings
[Click here for documentation](https://github.com/guyjbrown/bleepmanual/wiki/synthstrings)
]],

editor [[
sample("synth_strings_d4")
sleep(12)
push_fx("deep_phaser", {wetLevel=1,dryLevel=0})
push_fx("reverb_large", {wetLevel=0.4})
use_synth("synthstrings")
play(D5, {duration=2.5, level=0.5})
]],

markdown [[
## Juno pad
[Click here for documentation](https://github.com/guyjbrown/bleepmanual/wiki/junopad)
]],

editor [[
sample("juno_pad_d4")
sleep(12)
push_fx("roland_chorus", {wetLevel=1,dryLevel=0})
push_fx("reverb_large", {wetLevel=0.4})
use_synth("junopad")
play(D4, {duration=2.5, level=0.5})
]],

markdown [[
## Changing parameters
If you click on the documentation links above, you will see that each instrument 
has a number of parameters that can be changed. For example, to change the cutoff
frequency of the filter on the Juno pad to 800Hz, you can use the following code:
]],

editor [[
push_fx("roland_chorus", {wetLevel=1,dryLevel=0})
push_fx("reverb_large", {wetLevel=0.4})
use_synth("junopad")
play(D4, {duration=2.5, level=0.5, cutoff=800})
]],

}
bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Playing samples
]],

markdown [[
You can play a clip of sound using the **sample** command. Put the sample name in quotes.
]],

editor [[
sample("tbd_fxbed_loop")
]],

markdown [[
See the separate sheet for a list of samples. There are many to choose from. 
]],

editor [[
sample("tbd_voctone")
]],

markdown [[
Change the **rate** of the sample to get interesting effects. A rate less than 1 slows it down, greater than 1 speeds it up.
]],

editor [[
sample("tbd_voctone",{rate=0.5})
]],

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
Don't worry about using a sample straight. You can get a distinctive sound by changing the rate of a sample to extreme values.
The same sample can be made into percussion ...
]],

editor [[
sample("tbd_fxbed_loop",{rate=20})
]],

markdown [[
... or an atmospheric background for your track.
]],

editor [[
sample("tbd_fxbed_loop",{rate=0.1})
]],

markdown [[
You can also filter a sample to remove frequencies. Change the **cutoff** value to hear the effect.
]],

editor [[
sample("tbd_pad_3",{cutoff=300})
]],

markdown [[
You can also play samples with the **grain player**, which will stretch out a sample over time without changing its pitch.
]],

editor [[
grains("tbd_pad_1",{duration=8,
   size=0.9,
   density=10})
]],

}
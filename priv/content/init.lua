bpm = 120

content = {

markdown [[
Blank template
]],

editor [[
use_bpm(120)
use_synth("rolandtb")
play(C4)
]],

editor [[
    grains("guit_em9")
]],

markdown [[
## Pan control
Sampler now has a pan control, with lazy webaudio graph creation - we only create a StereoPannerNode
if a non-zero pan value is given.
]],

editor [[
for pan_value = - 1, 1, 0.2 do
  sample("guit_em9", {level=0.7,pan=pan_value})
  sleep(4)
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
]],

editor [[
]],

editor [[
]]

}
bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Drum patterns
]],

markdown [[
Let's make a techno drum pattern. Start with a kick drum on each beat. We use the **for** command to repeat the pattern 4 times.
]],

editor("kick",[[
for i = 1, 4 do
  drum_pattern("b--- b--- b--- b---", {
  b ="bd_sone",
  duration =0.25})
end
]]),

markdown [[
Now put a hi-hat on the off-beat (in between the kick drum sounds).
]],

editor("off hats",[[
for i = 1, 4 do
  drum_pattern("b-h- b-h- b-h- b-h-", {
  b ="bd_sone",
  h ="hat_gnu",
  duration =0.25})
end
]]),

markdown [[
In a different code box, add faster hi-hats at a lower volume. Press **Cue** on each box to hear them play together in time.
]],

editor("fast hats",[[
for i = 1, 4 do
  drum_pattern("xxxx xxxx xxxx xxxx", {
  x ="hat_metal",
  duration =0.25,
  level =0.1})
end
]]),

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
Start with  a short loop and try shifting one or two drum hits to create different rhythms.
]],

editor [[
for i = 1, 4 do
  drum_pattern("b-h- b-h- b-h- -bh-",{
  b ="bd_sone",
  h ="hat_gnu",
  duration =0.25})
end
]],

markdown [[
Try swapping the hi-hat and kick for other sounds. They should be in the same part of the pitch space (low/middle/high) as the original sounds otherwise the mix will become "muddy".
]],

editor [[
for i = 1, 4 do
  drum_pattern("htbT bthb btTh TtTb",{
     duration=0.25,
     b="tbd_perc_blip",
     h="tbd_perc_hat",
     t="tbd_perc_tap_1",
     T="tbd_perc_tap_2"})
end
]],

markdown [[
Use delay to turn simple rhythms into more complex ones. Add this line to one of the boxes above.
]],

editor [[
push_fx("stereo_delay",{wetLevel=0.2,feedback=0.1})
]],

}
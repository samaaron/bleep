bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Mixing and balancing parts
]],

markdown [[
When mixing your track, you need to use level adjustments and equalisation (EQ) to ensure that each sound is distinct.
]],

markdown [[
Here we've used an **EQ effect** to remove some low frequencies from the pad sound. Play the two boxes together, with and without the effect (use a comment `--` to remove the push_fx line). 
]],

markdown [[
The bass line is much more distinct if we apply the EQ. Also experiment with level changes.
]],

editor [[
push_fx("eqthree",{ lowFreq=1000, lowGain=- 12})
grains("tbd_pad_2",{
   duration=8,
   size=0.9, 
   density=10})]],

editor [[
use_synth("thickbass")
for i = 1, 16 do
  play(C2,{duration=0.2,
     env_mod=0.7,
     cutoff=1200,
     level=0.8})
  sleep(0.5)
end
]],

markdown [[
You can use **panning** to help separate different sounds. But don't go too mad; remember that your track needs to sound good on a single speaker too!
]],

editor [[
grains("tbd_pad_2", {duration=8,
   size=0.9,density=10,pan=- 0.5})
sleep(4)
sample("tbd_voctone", {pan=0.5})
]],

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
A **compressor effect** automatically lowers the volume of the loudest parts of a track. This can add "punch" and help to control levels. We use compression on individual parts, and the whole mix.
]],

markdown [[
Try this with and without the push_fx command, which adds a compressor effect.
]],

editor [[
push_fx("compressor", {
   threshold=- 12, 
   knee=5,   
   ratio=12, 
   attack=0.120, 
   release=0.2})
drum_pattern("B-h- B-h- B-hB B-h-", {
   duration=0.25,
   B ="bd_sone",
   h ="tbd_perc_hat"})
]],

}
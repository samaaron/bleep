bpm = 120

content = {

markdown [[
# A Techno Music Programming Masterclass With The Black Dog
## Repetition using loops
]],

markdown [[
Often you want to repeat sequences of notes or drum sounds. We can do this using a **loop**. The **for** command is used to count the number of repetitions (in this case, 8)
]],

editor [[
use_synth("rolandtb")
for i = 1, 8 do
  play(D2, {duration=0.25,
            env_mod=0.7,
            cutoff=600})
  sleep(0.5)
end
]],

markdown [[
The symbol **i** is a **variable** that contains a number. The first time around the loop it contains 1, then 2 and so on until it reaches 8. Then the loop stops. Now try this - can you see why the sequence is longer and faster?
]],

editor [[
use_synth("rolandtb")
for i = 1, 16 do
  play(D2, {duration=0.1,
            env_mod=0.7,
            cutoff=600})
  sleep(0.25)
end
]],

markdown [[
### Expert tips from The Black Dog
]],

markdown [[
The variable in a loop can be accessed inside the loop by writing its name. That means we can use it to control synth parameters.
]],

editor [[
use_synth("rolandtb")
for i = 1, 16 do
  play(D2, {duration=0.1,
            env_mod=0.7,
            cutoff=300 + 150 * i})
  sleep(0.25)
end
]],

markdown [[
When controlling synth parameters you can directly use the range of numbers you want in the for command. You can also specify a **step**. This varies the cutoff parameter from 300 to 1800 in steps of 100.
]],

editor [[
use_synth("rolandtb")
for i = 300, 1800, 100 do
  play(D2, {duration=0.1,
            env_mod=0.7,
            cutoff=i})
  sleep(0.25)
end
]],

}
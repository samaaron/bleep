-- Bleep Save

title = ""
author = ""
user_id = "bee70b1d-232c-48e1-9468-fb3fa908f8e8"
description = ""
bpm = 120
quantum = 4

init = [[
-- this code is automatically
-- inserted before every run
]]

content = {

markdown [[
## STEM Workshop August 2024 - Slides
]],

editor("1. Playing a sample", [[
-- 1. playing a sample

sample("loop_amen")
]]),

editor("2. Sample names", [[
-- 2. Using different sample names

sample("vinyl_scratch")
]]),

editor("3. Changing samples", [[
-- 3. Changing sample playback

sample("loop_amen", {rate=0.5})
sleep(8)
sample("loop_amen", {pan=1})
sleep(4)
sample("loop_amen", {cutoff=500})
]]),

editor("4. Making tunes", [[
-- 4. Making your own tunes

play(C4)
]]),

editor("5. Leaving gaps", [[
-- 5. Leaving gaps between notes

play(C4)
sleep(1)
play(E4)
]]),

editor("6. Play a tune", [[
-- 6. Play a simple tune

play(C4)
sleep(1)
play(D4)
sleep(1)
play(E4)
sleep(1)
play(C4)
]]),

editor("7. Change the sound", [[
-- 7. Changing the sound (synth)

use_synth("rolandtb")
play(C4)
sleep(1)
play(D4)
sleep(1)
play(E4)
sleep(1)
play(C4)
]]),

editor("8. Easier way", [[
-- 8. An easier way to play tunes

use_synth("rolandtb")
play_pattern({C4,D4,E4,C4})

sleep(3)

play_pattern({C4,D4,E4,C4}, {duration=0.25})

sleep(3)

play_pattern({C4,D4,E4,C4}, {duration=0.25,gate=0.5})

]]),

} -- end content

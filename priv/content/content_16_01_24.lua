content = {

markdown [[
### Lua redux - Map function for rings and array indexing
* Map function added as Sam suggested.
* Indexing has been changed so that Rings start at 1, consistent with Lua tables (otherwise moving between
rings and Lua tables will get very confusing I think).
* Array indexes can now be used to set and get values in a Ring.
]],

editor [[
use_synth("sawlead")
push_fx("reverb", {wetLevel=0.2})

-- set up some notes

the_notes = ring({C3,D3,E3,F3,G3})

-- map function suggested by Sam

the_notes:map(function (n)
    play(n, {duration=0.12})
    sleep(0.125)
end)

sleep(1)

-- the map function returns a new Ring so can be chained
-- there are easier ways of doing this obviously, but for a demo:

the_notes:map(function (n)
    return n + 12
end):map(function (n)
    play(n, {duration=0.12})
    sleep(0.125)
end)

sleep(1)

-- the imperative way, using array index style
-- indexes now count from 1 and of course wrap around

for i = 1, 10 do
    play(the_notes[i], {duration=0.12})
    sleep(0.125)
end
]],

markdown [[
### Lua redux - some new Ring functions
Two new functions for alternating notes and merging two Rings.
]],

editor [[
use_synth("sawlead")

-- alternate adds a duplicate to each note in the Ring shifted by a given
-- amount, in this case an octave down
-- @sam I note that the auto formatting spaces out the minus sign in negative numbers

the_notes = scale(harmonic_minor, C3, 1):alternate(- 12)
the_notes:map(function (n)
    play(n, {duration=0.12})
    sleep(0.125)
end)

sleep(1)

-- fuse two Rings by intercalating their notes
-- I am sorry for the 1980s reference but it must be done

use_synth("saveaprayer")
push_fx("chorus", {wetLevel=1,dryLevel=0})
push_fx("mono_delay", {wetLevel=0.3,delay=0.375,pan=0.5,feedback=0.1})
push_fx("reverb", {wetLevel=0.2})

-- melody line

duran = ring({D4,E4,F4,A4,C5,A4,C5,A4})

-- make 8 identical pedal notes

pedal = const_ring(8, D3)

-- combine them

duran_duran = duran:merge(pedal)

for i = 1, 2 do
    duran_duran:map(function (n)
    play(n, {duration=0.12,level=1})
    sleep(0.125)
    end)
end
]],

markdown [[
All the above is much easier using play_pattern

This has a similar syntax to play - a note list and then a table of parameters

The interesting bit is that parameters are now Rings (or made into Rings) so that you
can cycle around them to get various creative effects.
]],

editor [[
use_synth("fmbell")
push_fx("reverb", {wetLevel=0.2})

-- simple use

play_pattern({C4,D4,E4}, {
    duration=0.2,level=0.8})
sleep(1)

-- first parameter can be a Lua table or a Ring (or a scale, which is a Ring)
-- duration (or any parameter) can be a Ring and we cycle around the values

play_pattern(scale(lydian, D4, 2), {
    duration={0.2,0.1},
    level={0.8,0.4}})
sleep(1)

-- gate controls the proportion (0-1) of the duration that the note sounds for
-- this also shows cycling through cutoffs and different note sequences
-- with the same rhythmic pattern

use_synth("rolandtb")
push_fx("stereo_delay", {wetLevel=0.3,feedback=0.2,leftDelay=0.5,rightDelay=0.25})
for i = 1, 4 do
    the_notes = scale(phrygian_dominant, C2, 1):pick(8):clone(2)
    play_pattern(the_notes, {
    duration={0.5,0.125,0.125,0.25},
    gate={0.8,0.5},
    resonance=0.3,
    env_mod=0.5,
    cutoff={0.4,0.2,0.2}})
end
]],
markdown [[
### Lua redux - Rings update
Closely based on the approach in Sonic Pi, with the following implemented:
* `pick(n)` - selects n values in a new ring
* `clone(n)` - like repeat in Sonic Pi (repeat is a Lua keyword so we cant use it), returns a new ring that contains n copies
* `shuffle()` - returns a new ring that is random shuffle
* `reverse()` - returns a new ring that is time-reversed
* `stretch(n)` - duplicates each value n times, makes a new ring
* `length()` - get the length of the ring
* `head(n)` - makes a new ring from the first n elements
* `tail(n)` - makes a new ring from the last n elements
* `slice(a,b)` - returns a new ring sliced from a to b (first element is zero)
* `concat(r)` - concatenates the current ring with r, returns a new ring
* `multiply(s)` - returns a new ring, each element multiplied by s
* `add(s)` - return a new ring, each element summed with s
* `mirror()` - returns a mirror of the ring
* `reflect()` - returns a mirror with the duplicate middle element removed
* `sort()` - return a sorted ring
* **NEW!** `alternate(n)` - make alternating intervals by duplicating each value and adding a constant
* **NEW!** `merge(n)` - merge (intercalate) the values of two rings
* **NEW!** `quantize(n)` - quantise values in the ring to nearest n
* **NEW!** `const_ring(n,v)` - make a Ring of size n with constant value v
* **NEW!** `rand_ring(n,min,max)` - make a Ring of n random values between min and max
* **NEW!** `range_ring(n,min,max)` - make a range of n values between min and max

### chaining
As in Sonic Pi I have written all these so that rings are immutable and operations return a copy,
so you can chain operations together
### get and set
Get and set functions are provided but you can now use standard array index notation on rings.
]],

editor [[
use_synth("sawlead")
push_fx("stereo_delay", {leftDelay=0.5,rightDelay=0.25,wetLevel=0.1})

-- initial sequence
notes = ring({G3,B3,C4,E4,G4}):clone(2)
play_pattern(notes, {duration=0.125,gate=0.8})
sleep(0.5)

-- reversing
play_pattern(notes:reverse(), {duration=0.125,gate=0.8})
sleep(0.5)

-- adding a scalar
play_pattern(notes:add(7), {duration=0.125,gate=0.8})
sleep(0.5)

-- shuffling
play_pattern(notes:shuffle(), {duration=0.125,gate=0.8})
sleep(0.5)

-- pick and clone
play_pattern(notes:pick(2):clone(4), {duration=0.125,gate=0.8})
sleep(0.5)

-- stretch
play_pattern(notes:stretch(4), {duration=0.125,gate=0.8})
sleep(0.5)

-- quantise and random

dur = rand_ring(16, 1 / 16, 1 / 2):quantize(1 / 16)
play_pattern(scale(lydian, D3, 2), {
    duration = dur,
    gate = 0.8})
]],
markdown [[
### Scales
An implementation of scales, again very similar to Sonic Pi. A lot of scales are predefined which
are just Lua tables of MIDI note intervals such as {1,2,1,1,2,1} etc. These can be fractional for
microtonal scales. As in Sonic Pi, a scale is a Ring - so any of the functions above can be invoked
on a scale.

Demo updated 13/1/24 for indexing from 1 and using array index style.
]],

editor [[
-- simple major scale demo

use_synth("elpiano")
notes = scale(major, C3, 2)
play_pattern(notes, {
    duration=0.2,
    gate=0.9})
sleep(1)

-- random gamelan
-- scales can be microtonal!

use_synth("fmbell")
push_fx("stereo_delay", {wetLevel=0.1,leftDelay=0.4,rightDelay=0.6})
-- new reverb impulse responses!
push_fx("plate_large", {wetLevel=0.2})
upper = scale(pelog_sedeng, D4, 2):shuffle()
lower = scale(pelog_sedeng, D3):shuffle()
for i = 1, 32 do
    play(upper[i], {duration=0.15})
    if (i % 3 == 0) then
    play(lower[i], {duration=0.15})
    end
    sleep(0.2)
end
]],
markdown [[
### Lua redux - Drum patterns
Two functions for playing patterns:

**drum_pattern(s,params)** plays a drum pattern in x-xx form. Spaces are ignored. Parameters can be
single values or rings. A dash is a rest. Other characters can be defined as sample names - see examples.

**euclidean_pattern(h,n,p)** makes a euclidean pattern given the number of hits **h**, length of the sequence **n** and (optionally)
the phase **p**. A phase of p right-shifts the pattern to the right by p steps. A string is returned in x-xx form which can be used
with drum_pattern.
]],

editor [[
-- drum pattern works like play_pattern

drum_pattern("x--- --x- x--- ----", {
    x="bishi_bass_drum",
    duration=0.125})
sleep(1)

-- we are limited to one drum sound per time step, but we can use any characters
-- we like apart from space (ignored) and dash (rest)
-- other characters are mapped to the ring of samples, if given, in the order
-- they appear in the pattern string

drum_pattern("xx-x S-x- xx-- S-xx", {
    x="bishi_bass_drum",
    S="bishi_snare",
    duration=0.125})
sleep(1)

-- we can also add levels which cycle round to get a bit more feel

drum_pattern("xxxx xxxo xxxx xoxo", {
    x="bishi_closed_hat",
    o="hat_cats",
    level={1,0.3,0.5,0.3},
    duration=0.2})
sleep(1)

-- or we can mess with the sample rate
-- there is also a helper function to make euclidean rhythms

drum_pattern(euclidean_pattern(20, 32), {
    x="drum_tom_lo_soft",
    level={1,0.3,0.2,1,0.3,0.2,1.0,0.4},
    rate={1,1,2},
    duration=0.1})
sleep(1)

-- finally we can mess with durations to get swing
-- a helper function will calculate this for us and return a ring of durations
-- swing_16ths(amount,duration)
-- swing_8ths(amount,duration)

dur = swing_16ths(30, 0.125)

for i = 1, 2 do
    drum_pattern("Bxxx Sxxo Bxxx SxoS BxBx Sxxo Bxxx SxSS", {
    B="bishi_bass_drum",
    x="bishi_closed_hat",
    S="bishi_snare",
    o="hat_cats",
    level={1,0.3,0.5,0.3},
    duration=dur})
end
sleep(1)

-- firestarter

push_fx("reverb_medium", {wetLevel=0.1})

dur = swing_16ths(8, 0.1)

for i = 1, 4 do
  drum_pattern("BxxxSxxSxSxxSxxx", {
    B="bd_sone",
    x="bishi_closed_hat",
    S="bishi_snare",
    level={1,0.1,0.8,0.1},
    duration=dur})
end
]],

markdown [[
Bleeped on Bach - new patch, testing longer sequences with effects
]],

editor [[
t = 0.35
push_fx("stereo_delay", {wetLevel=0.1,feedback=0.3,leftDelay=3 * t,rightDelay=2 * t})
push_fx("reverb_large", {wetLevel=0.5})
push_fx("pico_pebble", {wetLevel=1,dryLevel=0})

use_synth("childhood")

s = scale(major, C4, 1.5)
root = 1
for i = 1, 12 do
    play_pattern({s[root],s[root+4],s[root+7],s[root+9]}, {
    duration=t,
    lfo_depth=1,
    gate=0.7,
    level={0.5,0.3,0.3,0.3}})
    root = root + 7
end
]]

}

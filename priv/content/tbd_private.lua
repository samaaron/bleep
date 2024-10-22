bpm = 120

content = {

   markdown [[
## New samples added
I changed the names to make them shorter and use underscores, they are as follows:
* tbd_fxbed_loop
* tbd_highkey_c4
* tbd_pad_1
* tbd_pad_2
* tbd_pad_3
* tbd_pad_4
* tbd_perc_blip
* tbd_perc_hat
* tbd_perc_tap_1
* tbd_perc_tap_2
* tbd_voctone
   ]],

markdown [[
To use the pads, you could use the grain synth to extend the time as shown below. Keeping the grain size long (0.9 sec)
and the density fairly low (10 grains/sec) should let you run it for extended periods of time, 20-30 seconds.
]],

editor [[
sample("tbd_fxbed_loop")
grains("tbd_pad_1", {
    duration=20,
    density=10,
    index=0.5,
    size=0.9})
]],

markdown [[
## Chorus name updated
Note that the chorus is now just called "chorus" and not "roland_chorus" - we decided to remove the trade name.
]],

markdown [[
## Three band EQ
We've now provided a three-band EQ that mirrors the functionality of the corresponding device in Ableton. 
* ``lowFreq`` - frequency of low cutoff in Hz (defaults to 400 Hz)
* ``highFreq`` - frequency of high cutoff in Hz (defaults to 4000 Hz)
* ``lowGain`` - gain of the low band (below ``lowFreq``) in dB from -30 to +30 (defaults to 0)
* ``midGain`` - gain of the mid band (between ``lowFreq`` and ``highFreq``) in dB from -30 to +30 (defaults to 0)
* ``highGain`` - gain of the high band (above ``highFreq``) in dB from -30 to +30 (defaults to 0)
]],

editor [[
push_fx("eqthree",{
   lowFreq=500,
   highFreq=2000,
   lowGain=-6,
   midGain=0,
   highGain=0})
sample("loop_amen")
]],

markdown [[
## Analogue lead
[Click here for documentation](https://github.com/guyjbrown/bleepmanual/wiki/analoguelead)
]],

editor [[
sample("analog_lead_d4")
sleep(5)
sample("analog_lead_d2")
sleep(6)
push_fx("chorus", {wetLevel=1,dryLevel=0})
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
push_fx("chorus", {wetLevel=1,dryLevel=0})
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
push_fx("chorus", {wetLevel=1,dryLevel=0})
push_fx("reverb_large", {wetLevel=0.4})
use_synth("junopad")
play(D4, {duration=2.5, level=0.5, cutoff=800})
]],

}
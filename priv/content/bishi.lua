bpm = 80

init = [[
  -- this code is automatically
  -- inserted before every run
]]

content = {
markdown [[
# Bishi : Who Has Seen The Wind
]],

markdown [[
### Introduction
In this tutorial you're going to learn how to recreate Bishi's track "Who Has Seen The Wind" using the **Bleep** system for music live coding.

Bleep let's you make music by writing computer program code. It's very cool! By doing this you'll learn some fundamental musical concepts and how to code, so you can create your own variations or the track or original compositions afterwards if you want.
]],

markdown [[
### The music video for "Who Has Seen The Wind"
Listen to the track and hear Bishi talking about it.
]],

markdown [[
### Making your first sounds with Bleep
Let's start with an example of what Bleep can do. Bleep can play sound samples - short sections of recorded sound. Press the **Cue** button on the box below:
]],

editor [[
sample("bishi_ah_call")
]],

markdown [[
That's Bishi singing! You can mess about with samples in Bleep to make them sound different if you want to. For example, we can make Bishi's voice sound lower or higher by setting the rate at which the sample plays back. A rate of 1 is normal speed. If we set the rate to 2 then it is twice as fast, so sounds an octave higher. 
]],

editor [[
sample("bishi_ah_call",{rate=2})
]],

markdown [[
Let's look at that line of code and break it down. Each line of the program is called a **statement**, and it does a small piece of work. The word ``sample`` is an instrution to play a sound sample. The name of the sample is a **string** of characters in quotes, in this case ``"bishi_ah_call"``. Finally, we can specify some **parameters** in curly brackets. In this case we set the parameter ``rate`` to a value by using the equals sign (which we call the **assignment operator**, since we assign a value to the parameter called rate). 
]],

markdown [[
**Experiment!** Try setting the rate to other values by changing the number and listen to the result by pressing Cue. You can try numbers less than 1 two as well, to make the sound really slow (try 0.2).
]],

markdown [[
### Using synths
We can also make sounds in Bleep using a **synth** (short for synthesizer). We've created a synth for you called ``bishiwobble`` which makes the wobbly bass sound that you can hear in Bishi's track. Any time you want to call up a synth you can write ``use_synth`` and then put the name of the one you want. Then you can use an instruction called ``play`` to make a sound with it:
]],

editor[[
use_synth("bishiwobble")
play(C2)
]],

markdown [[
Here, ``play`` is an instruction which tells the synth to play a note. ``C2`` means the note C two octaves below middle C:  pitch classes are indicated by note names (C, D, E etc) and octaves by numbers (1, 2, 3 etc).
]],

markdown [[
**Experiment!** Try note and octaves. Note names are C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B where "s" means "sharp". Notes range from A0 to G9. A0 is so low you will barely hear it. G9 is so high that it will annoy dogs.
]],

markdown [[
### Recreating the track
So how are we going to recreate the track? We've created a whole lot of synthesised sounds and samples and we're going to show you how you can use code to call these up at the right times. But what are "the right times"?

Have another listen to the track all the way through if you want, this time paying attention to its structure. Two things to notice. First, there are bits that repeat at the large-scale (verses and choruses) and at small-scale (e.g. the bass drum sounds repeat every four beats at the start) - that's useful because it means we can use a  coding principle of **looping**. Second, the track is made up of layers of different instrumental and vocal lines. That means we can recreate the track by creating one line at a time and having them play together.
]],

markdown [[
### Making the beat
Now let's make some cool beats. We can write a bass drum pattern in Bleep like this:
]],

editor[[
drum_pattern("B--- B--- B--- B---", {
    B="bishi_bass_drum",
    duration=0.25})
]],

markdown [[
In the drum pattern string, "B" means a bass drum sound and "-" means a silent gap. We say that "B" corresponds to the sample called ``bishi_bass_drum`` and the duration of each step in the pattern is 0.25. 
]],

markdown [[
**Experiment!** Try changing the duration to a different value between 0.1 and 2, such as 0.5. What happens?
]],

markdown [[
The bass drum pattern in Bishi's track is simpler, with just one bass drum hit at the start of the pattern like this:
]],

editor[[
drum_pattern("B--- ---- ---- ----", {
    B="bishi_bass_drum",
    duration=0.25})
]],

markdown [[
**Experiment!** Are you going to use Bishi's bass drum pattern or make your own? You can decide. Put a "B" in the pattern string where you want one. It will sound best if the number of "B" and "-" characters in the string adds up to 16 (spaces are ignored). You can also experiment with different bass drum sounds. Try these: ``bd_sone``, ``bd_tek``,``bd_boom``,``bd_zome`` or ``bd_chip``.
]],

markdown [[
Now we have a basic rhythm for the song but we can make it more interesting. Let's add a hi-hat (cymbal) sound called ``"bishi_closed_hat"`` and use the symbol ``x`` to represent it in the drum pattern. To give the rhythm a good groove we're going to place each hi-hat sound off the beat. Let's try it on the beat first.
]],

editor[[
drum_pattern("B--- x--- x--- x---", {
    B="bishi_bass_drum",
    x="bishi_closed_hat",
    duration=0.25})
]],

markdown [[
That's OK but it sounds like a dance track because the hi-hat coincides with the bass drum hits. Let's move the hi-hat off the beat by waiting for an 8th note first, and then waiting for an 8th note after each hit. That's still playing the hi-hat every beat (quarter note) but now we're playing "between" the bass drum hits rather than at the same time.  We've created **syncopation** - the hi-hat is playing on weak beats rather than strong beats.
]],

editor[[
drum_pattern("B-x- --x- --x- --x-", {
    B="bishi_bass_drum",
    x="bishi_closed_hat",
    duration=0.25})
]],

markdown [[
** Experiment!** Try variations of this pattern before moving on. You can also try some different hi-hat sounds such as ``hat_raw``, ``hat_tap`` or ``hat_gnu``. You could also mix it up by defining another symbol in the drum pattern (such as y) and alternating between different hi-hat or bass drum sounds.
]],

markdown [[
### Looping using the for statement
Let's put the main loop together now, by playing the bass wobble sound at the start followed by the drum pattern:
]],

editor [[
use_synth("bishiwobble")
play(C2)
drum_pattern("B-x- --x- --x- --x-", {
        B="bishi_bass_drum",
        x="bishi_closed_hat",
        duration=0.25})
]],

markdown [[
That's good, but it doesn't loop! We need to repeat this block of code several times to get a repeating loop, and we can do this using a statement called ``for``. This is what it looks like:
]],

editor [[
use_synth("bishiwobble")
for i=1,4 do
    play(C2)
    drum_pattern("B-x- --x- --x- --x-", {
            B="bishi_bass_drum",
            x="bishi_closed_hat",
            duration=0.25})
end
]],

markdown [[
The statements between the ``for`` and ``end`` words are repeated a number of times. How many times? That is controlled by the value of a **loop control variable**, which in this case is called ``i`` (it could be any name). Starting from its initial value (which is 1 in this example), each time around the loop we add one to the value of ``i`` and stop after we have done the last value specified. In this case, ``i`` counts through 1, 2, 3 and 4 in sequence. That means that the statements inside the loop (called the **loop body**) get repeated 4 times.
 ]],

 markdown [[
Notice how we formatted the program code here. The statements inside ``for`` and ``end`` have been moved to the right (**indented**) by a few spaces. This shows that the ``play`` and ``drum_pattern`` statements are inside the loop and will be repeated. Using indentation is a good habit to develop as you write code; it makes your programs easier to read. 
 ]],

 markdown [[
Here is a really badly formatted program! It does the same thing but is much harder to read.
 ]],

 editor [[
 use_synth("bishiwobble")
   for i=1,4 do
play(C2)
    drum_pattern("B-x- --x- --x- --x-", {
B="bishi_bass_drum",
      x="bishi_closed_hat",
   duration=0.25})
end
]],

 markdown [[
**Experiment!** Fix the horrible formatting of the code above. Then try changing the initial and final values of ``i`` in the loop. If you set a final value greater than 4 then you might have to wait a while for the sound to stop! If that happens and you get fed up, just reload this web page. What happens if you set the starting value to be greater than the final value, such as ``for i=3,1 do``? Can you explain what happens in that case?
]],



markdown [[
    # STOP HERE
]],


    editor [[
    push_fx("reverb", {wetLevel=0.1})
    use_synth("bishiwobble")
    for i = 1, 32 do
        play(C2)
        drum_pattern("B-x- --x- --x- --x-", {
                B="bishi_bass_drum",
                x="bishi_closed_hat",
                duration=0.25,
                level=1})
    end
    ]],

    markdown [[
    Syncopated snare
    ]],

    editor [[
    push_fx("reverb", {wetLevel=0.1})
    for i = 1, 32 do
        drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
                x="bishi_snare",
                level=0.2,
                duration=0.25})
    end
    ]],

    markdown [[
        Same again but through triplet delay and gated snare
        ]],

    editor [[
    push_fx("mono_delay", {delay=0.375,wetLevel=0.2,dryLevel=0.8})
    push_fx("ambience_gated", {wetLevel=1,dryLevel=0})
    for i = 1, 32 do
    drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
                x="bishi_snare",
                level=0.4,
                duration=0.25})
    end
    ]],

    markdown [[
    Synths
        ]],

    editor [[
    use_synth("bishibass")
    push_fx("mono_delay", {wetLevel=0.25,feedback=0.2,delay=0.375,pan=0.5})
    for i = 1, 32 do
        play_pattern({C3,C4,C3,C4,F3,G3,As3}, {
                    duration={0.75,3.25,0.75,1.25,0.75,0.75,0.5},
                    level=0.1})
    end
    ]],

    markdown [[
    Vocals
    ]],

    editor [[
    push_fx("reverb", {wetLevel=0.1})
    for i = 1, 2 do
        sample("bishi_ah")
        sleep(3)
        sample("bishi_ahah")
        sleep(5)
    end
    ]],

    editor [[
        push_fx("reverb", {wetLevel=0.1})
        for i = 1, 2 do
            sample("bishi_ah")
            sample("bishi_ah_harmony")
            sleep(3)
            sample("bishi_ahah")
            sample("bishi_ahah_harmony")
            sleep(5)
        end
    ]],
    editor [[
        push_fx("reverb_large", {wetLevel=0.25})
        for i = 1, 2 do
            sleep(1.25)
            sample("bishi_ah_call",{level=0.5})
            sleep(3.5)
            sample("bishi_ah_reply",{level=0.5})
            sleep(3.25)
        end
    ]],
    editor [[
        push_fx("reverb_large", {wetLevel=0.2})
        sample("bishi_verse")
    ]],
    markdown [[
        Cool synthy middle bit (what do we do about the sitar?)
    ]],
    editor [[
    use_synth("sawlead")
    push_fx("deep_phaser", {wetLevel=0.8,dryLevel=0.2})
    push_fx("mono_delay", {wetLevel=0.1,delay=0.5,pan=0.9})
    notes = ring({G5,F5,Ds5,C5})
    freq = range_ring(8, 0.1, 0.5)
    for i = 1, 16 do
        play_pattern(notes, {
            duration=0.25,
            cutoff=freq[i],
            gate=0.75,
            filter_mod=0.4,
            filter_attack=0.05,
        level={0.2,0.1,0.1,0.1}})
    end
    ]],
    editor [[
    use_synth("sawlead")
    push_fx("mono_delay", {wetLevel=0.1,delay=0.75,pan=- 0.9})
    notes = ring({G4,As4,C5}):clone(2)
    for i = 1, 4 do
        play_pattern(notes, {
            duration=0.25,
            cutoff=0.3,
            gate=0.9,
            filter_attack=0.05,
        level={0.1,0.05,0.05}})
        sleep(2.5)
    end
    ]],
    editor [[
    for i=1,2 do
        sample("bishi_down_dini")
        sleep(8)
    end
    ]]


}

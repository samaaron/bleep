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

video [[
  bishi_1080
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
Let's look at that line of code and break it down. Each line of the program is called a **statement**, and it does a small piece of work. The word ``sample`` is an instruction to play a sound sample. The name of the sample is a **string** of characters in quotes, in this case ``"bishi_ah_call"``. Finally, we can specify some **parameters** in curly brackets. In this case we set the parameter ``rate`` to a value by using the equals sign (which we call the **assignment operator**, since we assign a value to the parameter called ``rate``).
]],

markdown [[
**Experiment!** Try setting ``rate`` to other values by changing the number and listen to the result by pressing Cue. You can try numbers less than 1 two as well, to make the sound really slow (try 0.2).
]],

markdown [[
### Using synths
We can also make sounds in Bleep using a **synth** (short for synthesizer). We've created a synth for you called ``bishiwobble`` which makes the wobbly bass sound that you can hear in Bishi's track. Any time you want to call up a synth you can write ``use_synth`` and then put the name of the one you want. Then you use an instruction called ``play`` to make a sound with it:
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
Let's being by making some cool beats! We can write a bass drum pattern in Bleep like this:
]],

editor[[
drum_pattern("b--- b--- b--- b---", {
    b="bishi_bass_drum",
    duration=0.25})
]],

markdown [[
In the drum pattern string, `b` means a bass drum sound and `-` means a silent gap. We say that `b` corresponds to the sample called ``"bishi_bass_drum"` and the duration of each step in the pattern is 0.25.
]],

markdown [[
**Experiment!** Try changing the duration to a different value between 0.1 and 2, such as 0.5. What happens?
]],

markdown [[
The bass drum pattern in Bishi's track is simpler, with just one bass drum hit at the start of the pattern like this:
]],

editor[[
drum_pattern("b--- ---- ---- ----", {
    b="bishi_bass_drum",
    duration=0.25})
]],

markdown [[
**Experiment!** Are you going to use Bishi's bass drum pattern or make your own? You can decide. Put a `b` in the pattern string where you want one. It will sound best if the number of `b` and `-` characters in the string add up to 16 (spaces are ignored). You can also experiment with different bass drum sounds. Try these: ``"bd_sone"``, ``"bd_tek"``,``"bd_boom"``,``"bd_zome"`` or ``"bd_chip"``.
]],

markdown [[
Now we have a basic rhythm for the song but we can make it more interesting. Let's add a hi-hat (cymbal) sound called ``"bishi_closed_hat"`` and use the symbol ``x`` to represent it in the drum pattern. To give the rhythm a good groove we're going to place each hi-hat sound off the beat. Let's try it on the beat first.
]],

editor[[
drum_pattern("b--- x--- x--- x---", {
    b="bishi_bass_drum",
    x="bishi_closed_hat",
    duration=0.25})
]],

markdown [[
That's OK but it sounds like a dance track because the hi-hat is on the beat. Let's move the hi-hat off the beat by waiting for an 8th note first, and then waiting for an 8th note after each hit. That's still playing the hi-hat every beat (quarter note) but now we're playing "between" the bass drum hits rather than at the same time.  We've created **syncopation** - the hi-hat is playing on weak beats rather than strong beats.
]],

editor[[
drum_pattern("b-x- --x- --x- --x-", {
    b="bishi_bass_drum",
    x="bishi_closed_hat",
    duration=0.25})
]],

markdown [[
** Experiment!** Try variations of this pattern before moving on. You can also try some different hi-hat sounds such as ``"hat_raw"``, ``"hat_tap"`` or ``"hat_gnu"``. You could also mix it up by defining another symbol in the drum pattern (such as `y`) and alternating between different hi-hat or bass drum sounds.
]],

markdown [[
### Looping using the for statement
Let's put the main loop together now, by playing the bass wobble sound at the start followed by the drum pattern:
]],

editor [[
use_synth("bishiwobble")
play(C2)
drum_pattern("b-x- --x- --x- --x-", {
        b="bishi_bass_drum",
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
    drum_pattern("b-x- --x- --x- --x-", {
            b="bishi_bass_drum",
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
    drum_pattern("b-x- --x- --x- --x-", {
b="bishi_bass_drum",
      x="bishi_closed_hat",
   duration=0.25})
end
]],

 markdown [[
**Experiment!** Fix the horrible formatting of the code above. Then try changing the initial and final values of ``i`` in the loop. If you set a final value greater than 4 then you might have to wait a while for the sound to stop! If that happens and you get fed up, just reload this web page. What happens if you set the starting value to be greater than the final value, such as ``for i=3,1 do``? Can you explain what happens in that case?
]],


markdown [[
### Adding effects - reverb
If you play this loop now you'll notice that it still doesn't sound quite right - it's got a sharp cut-off to the sounds. We can change this by adding reverberation ("reverb" for short) to the sound.

Reverb is what happens when sound reflects off surfaces, and it can give us a sense of the space that the sound is happening in. In this case we want the original sound (sometimes called the "dry sound") to carry on and decay a bit longer so we're going to add reverb to that original sound signal. Dry sound with reverb added is called "wet sound"! So we set the amount of reverb using a parameter called `wetLevel` that takes a value between 0 and 1. As with all the values here, the higher the value, the more of the effect will be applied to the sound. We can add that to the start of this block of code so that it applies to the whole of this sound block. Here we go:
]],

editor [[
push_fx("reverb", {wetLevel=0.1})
use_synth("bishiwobble")
for i = 1, 4 do
    play(C2)
    drum_pattern("B-x- --x- --x- --x-", {
            B="bishi_bass_drum",
            x="bishi_closed_hat",
            duration=0.25})
end
]],

markdown [[
**Experiment!** Try different amounts of reverb by setting ``wetLevel`` to a value between 0 and 1. You'll probably find that too much reverb sounds like the music is playing in a giant cave! With reverb, a little goes a long way.
]],

markdown [[
### Creating interest with a syncopated snare drum pattern
That's got a nice feel to it, good! Now we're going to add some snare hits. These have quite a complicated rhythm to give the track interest, so we're going to define a pattern for these using `s` to indicate where there is a snare hit:
]],

editor [[
for i = 1, 2 do
    drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
        x="bishi_snare",
        level=0.2,
        duration=0.25})
end
]],

markdown[[
Press the Cue button on the two boxes above, and you should hear both drum loops play together.
]],

markdown [[
**Experiment!** In the code above, notice that we used a parameter called `level` to set the sound level (volume) of the snare drum. Try setting that to different values between 0 and 1, and see how it changes the feel of the rhythm. You can also try different drum sounds such as `"elec_hi_snare"`, `"elec_flip"`,`"perc_snap"` or `"tabla_na_o"`.
]],

markdown[[
### Adding delay to the snare
Delay is a very important effect in electronic music. We can introduce delay in the same way that we made reverb, by using the instruction ``push_fx`` to make a new audio effect. We set the delay time (in seconds), wet level and dry level:
]],

editor [[
push_fx("mono_delay", {delay=0.375,wetLevel=0.2,dryLevel=0.8})
for i = 1, 2 do
drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
    x="bishi_snare",
    level=0.2,
    duration=0.25})
end
]],

markdown[[
Play the delayed snare with the main drum loop and listen to the way that the echoes become part of the rhythm, giving it a bit more feel and motion.
]],

markdown[[
### Adding Bishi's vocal harmonies to the mix
The other sound we hear at the start is Bishi's voice. If you listen to the opening of the track again, you'll notice that it's not just Bishi's solo voice that we hear: she has layered her voice so that it creates harmonies.

We've created Bishi's vocal harmonies as two samples: the first single harmony “ah” which we call `"bishi_ah"` and then the subsequent two-notes `"bishi_ahah"`. We want to put these together to create the whole phrase so we do this by playing the first sample and then waiting for a number of beats using the `sleep` instruction.

Also, we want the vocals to have some reverb so we add that as well.
]],

editor[[
push_fx("reverb", {wetLevel=0.1})
sample("bishi_ah")
sleep(3)
sample("bishi_ahah")
sleep(5)
]],

markdown[[
Now we can play more samples to build up a harmony (a chord) in layers. The first sample plays the tonic, whereas the second sample adds the third note of the (major) scale, and another on the fifth of the scale.
]],

editor [[
push_fx("reverb", {wetLevel=0.1})
sample("bishi_ah")
sample("bishi_ah_harmony")
sleep(3)
sample("bishi_ahah")
sample("bishi_ahah_harmony")
sleep(5)
]],

markdown[[
There are also some lovely "call and reply" vocals that we can add. Let's add a bit more reverb to them too. We're going to do that by increasing `wetLevel` but also using a larger "room" for the reverberation, called `"reverb_large"`.
]],

editor[[
push_fx("reverb_large", {wetLevel=0.3})
sleep(1.25)
sample("bishi_ah_call")
sleep(3.5)
sample("bishi_ah_reply")
sleep(3.25)
]],

markdown[[
### Creating a synth bass line
You'll also notice that there is a repeating bass synth sound in Bishi's track. This is a looping sequence of notes that we can describe using a `play_pattern` statement. The general form of this is
``play_pattern(list_of_notes,list_of_parameters)``
Remember that we represent lists in curly brackets, using commas to separate the values. The first note has a duration of 0.75, the second has a duration of 3.25, and so on. So we can represent the bass sequence like this:
]],

editor[[
use_synth("bishibass")
play_pattern({C3,C4,C3,C4,F3,G3,As3}, {
    duration={0.75,3.25,0.75,1.25,0.75,0.75,0.5},
    level=0.1
})
]],

markdown[[
Hmmm, that's the right notes but it doesn't sound very good. This is another part of Bishi's track where the use of delay is really important to give the music a bit more rhythm and movement. Let's add delay to the synth to see this.
]],

editor[[
push_fx("mono_delay",{wetLevel=0.3,delay=0.375})
use_synth("bishibass")
play_pattern({C3,C4,C3,C4,F3,G3,As3}, {
    duration={0.75,3.25,0.75,1.25,0.75,0.75,0.5},
    level=0.1
})
]],

markdown[[
### Putting it all together
Finally, let's put everything we've done together to make the first verse of Bishi's song. Here are all the loops you need shown one after the other. You can press the Cue buttons to start each one. We've adjusted the loops in each code block to give the right number of repetitions for the first verse. Also, we've added a lead vocal with some reverb at the end. Listen to the track again, and then try playing the boxes at the right time to make the verse.
]],

editor[[
push_fx("reverb", {wetLevel=0.1})
use_synth("bishiwobble")
for i = 1, 32 do
    play(C2)
    drum_pattern("b-x- --x- --x- --x-", {
            b="bishi_bass_drum",
            x="bishi_closed_hat",
            duration=0.25})
end
]],

editor[[
push_fx("mono_delay", {delay=0.375,wetLevel=0.2,dryLevel=0.8})
for i = 1, 32 do
drum_pattern("xx-- x--x ---- ---x ---- -x-- ---- xx--", {
    x="bishi_snare",
    level=0.2,
    duration=0.25})
end
]],

editor[[
push_fx("mono_delay",{wetLevel=0.3,delay=0.375})
use_synth("bishibass")
for i = 1, 32 do
    play_pattern({C3,C4,C3,C4,F3,G3,As3}, {
        duration={0.75,3.25,0.75,1.25,0.75,0.75,0.5},
        level=0.1
    })
end
]],

editor[[
push_fx("reverb", {wetLevel=0.1})
sample("bishi_ah")
sleep(3)
sample("bishi_ahah")
sleep(5)
]],

editor[[
push_fx("reverb", {wetLevel=0.1})
sample("bishi_ah")
sample("bishi_ah_harmony")
sleep(3)
sample("bishi_ahah")
sample("bishi_ahah_harmony")
sleep(5)
]],

editor[[
push_fx("reverb_large", {wetLevel=0.3})
sleep(1.25)
sample("bishi_ah_call")
sleep(3.5)
sample("bishi_ah_reply")
sleep(3.25)
]],

editor[[
push_fx("reverb_large", {wetLevel=0.25})
sample("bishi_verse")
]],

markdown[[
### Next steps
We hope you enjoyed this first exercise in live coding with Bishi's music! Along the way you learned some important ideas in coding and music. Keep experimenting with the code on this page to make your own variations of Bishi's track, and remember - in live coding there are no mistakes, just creative opportunities!
]],

}

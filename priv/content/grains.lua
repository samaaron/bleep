bpm = 120

content = {

markdown [[
# Granular synthesis in bleep

Bleep supports granular synthesis through the ``grains`` function. This function takes a sample name 
as an argument and plays back many short sections of the sample ("grains") in quick succession. You can decide
where in the sample the grains are taken from, their size, the grain density and how the grains are 
positioned in the stereo field. You can also apply an envelope and a lowpass filter over the whole sound. 
]],

markdown[[
Granular synthesis is a powerful technique for creating new sounds from existing samples. It's great for making
atmospheres and pads, but can also be used for more percussive sounds. 
]],

markdown[[
Here's a quick demo of granular synthesis in bleep. 
]],


editor [[
push_fx("reverb_large", {wetLevel=0.4})

grains("grains_throat", {
    attack = 0.1,
    decay = 0.1,
    sustain = 1,
    release = 0.5,
    duration = 20,
    density = 15,
    index = 0.7,
    index_var = 0.002,
    size = 0.7,
    shape = 0.5,
    level = 0.4,
    pan_var = 0.9,
    time_var = 0.1})

grains("grains_bells", {
    pan_var = 1,
    duration = 20,
    density = 3,
    index = 0,
    index_var = 0.01,
    time_var = 0.15,
    size = 0.5,
    shape = 0,
    level = 0.2,
    detune = 800,
    detune_var = 500})
]],

markdown [[
# How does it work?
In bleep, granular synthesis uses a **playhead** that moves slowly through the sample over the duration of the
note. The initial position of the playhead is determined by the ``index`` parameter, and the amount that it changes 
ovr the duration of the note is determined by the ``index_var`` parameter. At each point in time, grains are 
made from the position in the sample at the playhead, plus a bit of random variation that is given by ``time_var`` 
parameter. How many grains per made is determined by the ``density`` parameter. The sample can be tuned up and
down by setting a detune amount, and random detuning can be applied to each grain. Each grain can be randomly
panned too.
]],

markdown[[
All this sounds like a lot of work for bleep to do, and it is. It is not advised to set the duration of a 
grains sound to a very long time (say, more than 10 seconds). You might run into memory problems.
]],

markdown [[
# Summary of parameters

| Parameter | Minimum | Maximum | Default | Description |
|-----------|---------|---------|---------|-------------|
| attack    | 0       | 5       | 0.01    | Attack in seconds |
| cutoff    | 20      | 20000   | 20000   | Filter cutoff in Hz |
| density   | 1       | 20      | 10      | Grain density in grains per second |
| detune    | -2400   | 2400    | 0       | Sample detune in cents |
| detune_var| 0       | 2400    | 0       | Pitch variance in cents |
| duration  | 0.02    | 100     | 1       | Duration in seconds |
| index     | 0       | 1       | 0.5     | Buffer index |
| index_var | 0       | 1       | 0.01    | Time variance |
| level     | 0       | 1       | 0.8     | Overall volume |
| pan       | -1      | 1       | 0       | Pan |
| pan_var   | 0       | 1       | 0       | Pan variance |
| rate      | 0.1     | 10      | 1       | Sample rate multiplier |
| release   | 0       | 5       | 2       | Release in seconds |
| resonance | 0       | 25      | 0       | Filter resonance |
| shape     | 0       | 1       | 0.5     | Grain shape |
| size      | 0.1     | 1       | 0.2     | Grain size in sec |
| time_var  | 0       | 0.1     | 0.05    | Time variance of grain start (jitter) |
]],

markdown [[
# size
This determines the length of each grain in seconds. Short grains won't overlap and give a roughly textured or bubbly 
sound. Longer grains will overlap in time and give a smoother sound.
]],

editor [[
for _, size_value in ipairs({0.1,0.5,2}) do
    grains("grains_throat", {
        index = 0.7,
        index_var = 0,
        shape = 0.5,
        size = size_value
    })
    sleep(8)
end
]],

markdown [[
# shape
This determines the shape of the grain envelope. A value of 0 will produce a grain with an abrupt
start that decays linearly to zero (down-ramp). A shape of 0.5 is a triangle, and a shape of 1 starts at zero and
linearly increases to one (up-ramp).
]],

markdown [[
Note that an up-ramp can give the impression that the sample is being played backwards (it isn't!).
]],

editor [[
for _, shape_value in ipairs({0,0.4,1}) do
    grains("grains_throat", {
        index = 0.7,
        index_var = 0,
        shape = shape_value,
        size = 0.5
    })
    sleep(8)
end
]],

}
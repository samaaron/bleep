bpm = 120

content = {

markdown [[
## dice(n)
The ```dice(n)``` function is like throwing a die with n sides, you get an integer between 1 and n. For example, 
if on average you wanted a quarter of your hi-hat sounds to be "hat_raw" and three-quarters to be "hat_gnu" then the following
will do the job:
]],

editor [[
for i = 1, 16 do
    if dice(4) == 1 then
        sample("hat_raw")
    else
        sample("hat_gnu")
    end
    sleep(0.25)
end
]],

markdown [[
## set_seed(n)
If you run the code above several times you'll get a different result on each run. You may want a sequence to be
random but reproducible, so it's the same each time you click the run button. To do this, you can set a **seed**
for the random number generator. Different seeds give different random patterns. 
]],

markdown [[
The seed is just an integer number. Try changing the argument to ```set_seed``` below to get different random patterns. 
]],

markdown [[
If you miss out the argument and just call ```set_seed()``` then the system clock is used to seed the random numbers,
and you'll get a different result on each run. 
]],

editor [[
set_seed(1234)
for i = 1, 16 do
    if dice(4) == 1 then
        sample("hat_raw")
    else
        sample("hat_gnu")
    end
    sleep(0.25)
end
]],

markdown [[
## randi(min,max)
This returns a random integer between ```min``` and ```max```. 
]],

editor [[
use_synth("rolandtb")
for i = 1, 16 do
    play(C2, {cutoff=randi(200, 2000),resonance=0.4,duration=0.15})
    sleep(0.25)
end
]],

markdown [[
As before you can call ```set_seed``` to get a reproducible sequence of random numbers from randi.
]],

editor [[
set_seed(1635)
use_synth("rolandtb")
for i = 1, 16 do
    play(C2, {cutoff=randi(200, 2000),resonance=0.4,duration=0.15})
    sleep(0.25)
end
]],

markdown [[
## randf(min,max)
This returns a random floating point number between ```min``` and ```max```. 
]],

editor [[
for i = 1, 8 do
    sample("guit_em9",{pan=randf(-1,1)})
    sleep(4)
end
]],

markdown [[
## Putting it all together
Let's finish with a drum solo. 
]],

editor [[
set_seed(1947)
-- an array of tabla sample names
tabla = {"tabla_ghe1","tabla_na","tabla_te1","tabla_tun2","tabla_dhec"}
for i = 1, 32 do
    -- randomly select a sample name
    tb = tabla[dice(5)]
    -- random level between 0.5 and 0.9
    lv = randf(0.5,0.9)
    -- random pan between -0.5 and 0.5
    pv = randf(-0.5,0.5)
    -- play it
    sample(tb,{pan=pv, level=lv})
    sleep(0.25)
end
]],

}
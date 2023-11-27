export const bigoctave = String.raw`@synth
long-name : "Big Octave"
short-name : "bigoctave"
version : "1.0"
author : "Guy Brown"
doc : "Big saw synth sound with sub octave"
@end

-- modules

TRI-OSC : lfo
PULSE-OSC : pwm
SAW-OSC : saw
SQR-OSC : sub
VCA : pwmgain
VCA : sawgain
VCA : subgain
VCA : lfogain
VCA : mixer
HPF : hpf
LPF : vcf
LPF : lowpass
VCA : vca
ADSR : ampenv
ADSR : vcfenv

-- patching

lfo.out -> lfogain.in
lfogain.out -> pwm.pulsewidthCV
pwm.out -> pwmgain.in
saw.out -> sawgain.in
sub.out -> subgain.in
pwmgain.out -> mixer.in
sawgain.out -> mixer.in
subgain.out -> mixer.in
mixer.out -> hpf.in
hpf.out -> vcf.in
vcf.out -> lowpass.in
lowpass.out -> vca.in
vca.out -> audio.in
ampenv.out -> vca.levelCV
vcfenv.out -> vcf.cutoffCV

-- control

pwm.pitch = keyboard.pitch
saw.pitch = keyboard.pitch
sub.pitch = keyboard.pitch
sub.detune = -1200

-- parameters

-- LFO range for Juno 106
-- LFO rate is 0p1 Hz to 30Hz
-- LFO delay is 0 to 3s

lfo.pitch = 4
lfogain.level = 0.1
pwm.pulsewidth = 8
pwmgain.level = 0
sawgain.level = 0.6
subgain.level = 0.4
hpf.cutoff = 10
vcf.resonance = 5
mixer.level = 0.4
lowpass.resonance = 0
lowpass.cutoff = keyboard.cutoff | map(500,15000)

-- slider ranges for Juno 106 are
-- attack 1p5 ms to 3s
-- decay 1p5ms to 12s
-- release 1p5ms to 12s

ampenv.level = keyboard.level
ampenv.attack = 0.01
ampenv.decay = 0.4
ampenv.sustain = keyboard.level
ampenv.release = 0.05

vcfenv.level = keyboard.pitch | map(5000,10000)
vcfenv.attack = 0
vcfenv.decay = 0.5
vcfenv.sustain = keyboard.pitch | map(1000,2000)
vcfenv.release = 0.2

-- end
`
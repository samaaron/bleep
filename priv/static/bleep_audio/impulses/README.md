# Lexicon 480L impulse responses

These impulse responses were recorded from a Lexicon 480L by Big Gee and are
widely available on internet file sharing sites. These files are in
the public domain and have been made available without any licence restrictions.

Source:

https://www.housecallfm.com/download-gns-personal-lexicon-480l

We renamed the files for consistency and saved them in FLAC format 16 bit, 44.1 kHz, 2 channel and trimmed the low-amplitude tail (below 0.01%) to make them more compact:

```
for file in *.aif; do sox $file -r 44100 -b 16 -c 2 -t flac ./FLAC/${file%.*}.flc -V reverse silence 1 0.1 0.01% reverse; done
```

# OpenAIR impulses responses

Obtained from https://www.openair.hosted.york.ac.uk/ at the University of York
Distributed under CC4.0 https://creativecommons.org/licenses/by/4.0/

We converted these to FLAC 16 bit 44.1 kHz but otherwise didn't mess with them.

# Selected impulse responses

| bleep name | filename | description | source |
| ---------- | -------- | ----------- | ------ |
| reverb | hall-medium.flc | Medium hall | Lexicon |
| reverb-massive | reactor-hall.flc | R1 nuclear reactor hall | OpenAIR |
| reverb-large | hall-large-church.flc | Large church | Lexicon |
| reverb-medium | hall-medium.flc | Medium hall | Lexicon |
| reverb-small | hall-small.flc | Small hall | Lexicon |
| room-large | room-large.flc | Large room | Lexicon |
| room-small | room-small-bright.flc | Small room | Lexicon |
| plate-drums | plate-snare.flc | Plate reverb suitable for drums | Lexicon |
| plate-vocal | rich-plate-vocal-2.flc | Plate reverb suitable for vocals | Lexicon |
| plate-large | plate-large.flc | Large plate reverb | Lexicon |
| plate-small | plate-small.flc | Small plate reverb | Lexicon |
| ambience-large | ambience-large.flc | Large ambience | Lexicon | 
| ambience-medium | ambience-medium.flc | Medium ambience | Lexicon | 
| ambience-small |ambience-small.flc | Small ambience | Lexicon | 


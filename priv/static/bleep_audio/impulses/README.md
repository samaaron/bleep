# Lexicon 480L impulse responses

These impulse responses were recorded from a Lexicon 480L by Big Gee and are
widely available on internet file sharing sites. These files are in
the public domain and have been made available without any licence restrictions.

Source:

https://www.housecallfm.com/download-gns-personal-lexicon-480l

We renamed the files for consistency and saved them in FLAC format 16 bit, 44.1 kHz, 2 channel and trimmed the low-amplitude tail (below 0.01%) to make them more compact:

```
for file in *.aif; do sox $file -r 44100 -b 16 -c 2 -t flac ./FLAC/${file%.*}.flac -V reverse silence 1 0.1 0.01% reverse; done
```

# OpenAIR impulses responses

Obtained from https://www.openair.hosted.york.ac.uk/ at the University of York
Distributed under CC4.0 https://creativecommons.org/licenses/by/4.0/

We converted these to FLAC 16 bit 44.1 kHz stereo.

# Microphone impulse responses

Public domain, from the Microphone Impulse Response Project

We converted these to FLAC 16 bit 44.1 kHz mono.

# Bleep names for selected impulse responses

| bleep name | filename | description | source |
| ---------- | -------- | ----------- | ------ |
| reverb | hall-medium.flac | Medium hall | Lexicon |
| reverb-massive | reactor-hall.flac | R1 nuclear reactor hall | OpenAIR |
| reverb-large | hall-large-church.flac | Large church | Lexicon |
| reverb-medium | hall-medium.flac | Medium hall | Lexicon |
| reverb-small | hall-small.flac | Small hall | Lexicon |
| room-large | room-large.flac | Large room | Lexicon |
| room-small | room-small-bright.flac | Small room | Lexicon |
| plate-drums | plate-snare.flac | Plate reverb suitable for drums | Lexicon |
| plate-vocal | rich-plate-vocal-2.flac | Plate reverb suitable for vocals | Lexicon |
| plate-large | plate-large.flac | Large plate reverb | Lexicon |
| plate-small | plate-small.flac | Small plate reverb | Lexicon |
| ambience-large | ambience-large.flac | Large ambience | Lexicon | 
| ambience-medium | ambience-medium.flac | Medium ambience | Lexicon | 
| ambience-small |ambience-small.flac | Small ambience | Lexicon | 
| mic-reslo | IR_ResloURA.flac | Reslo UR ribbon microphone | MicIRP |
| mic-beyer | IR_BeyerM500Stock.flac | Beyer M500 ribbon microphone | MicIRP |
| mic-foster | IR_FosterDynamicDF1.flac | Foster DF1 dynamic microphone | MicIRP |
| mic-lomo | IR_Lomo52A5M.flac | Lomo 52-5M dynamic microphone | MicIRP |


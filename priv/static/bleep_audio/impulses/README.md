# Lexicon 480L Impulse Responses

These impulse responses were recorded from a Lexicon 480L by Big Gee and are
widely available on internet file sharing sites. We believe these files are in
the public domain and have been made available without any licence restrictions.

Source:

https://www.housecallfm.com/download-gns-personal-lexicon-480l

We renamed the files for consistency and saved them in FLAC format 16 bit, 44.1 kHz, 2 channel and trimmed the low-amplitude tail (below 0.01%) to make them more compact:

```
for file in *.aif; do sox $file -r 44100 -b 16 -c 2 -t flac ./FLAC/${file%.*}.flc -V reverse silence 1 0.1 0.01% reverse; done
```
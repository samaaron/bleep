import Monitor from "./monitor";
import Generator from "./generator";
import Player from "./player";
import Grammar from "./grammar";
import {Reverb, RolandChorus, StereoDelay, EffectsChain} from "./effects";

export default class BleepAudioCore {
  #audio_context;
  #monitor;
  #loaded_synthgens = new Map();
  #loaded_buffers = new Map();
  #initial_audio_context_time_s = 0;
  #base_audio_context_time_s = 0;
  #initial_wallclock_time_s = 0;
  #started = false;
  #default_synthdef_paths;
  #reverb
  #chorus
  #delay

  constructor() {
    this.#monitor = new Monitor();
    this.#default_synthdef_paths = [
      "/bleep_audio/synthdefs/bishi-fatbass.txt",
      "/bleep_audio/synthdefs/bishi-wobble.txt",
      "/bleep_audio/synthdefs/brasspad.txt",
      "/bleep_audio/synthdefs/buzzer.txt",
      "/bleep_audio/synthdefs/catholicstyle.txt",
      "/bleep_audio/synthdefs/choir.txt",
      "/bleep_audio/synthdefs/default.txt",
      "/bleep_audio/synthdefs/elpiano.txt",
      "/bleep_audio/synthdefs/filterwobble.txt",
      "/bleep_audio/synthdefs/fmbell.txt",
      "/bleep_audio/synthdefs/funkybass.txt",
      "/bleep_audio/synthdefs/hammond.txt",
      "/bleep_audio/synthdefs/ninth.txt",
      "/bleep_audio/synthdefs/pantest.txt",
      "/bleep_audio/synthdefs/randomblips.txt",
      "/bleep_audio/synthdefs/rolandtb.txt",
      "/bleep_audio/synthdefs/sawlead.txt",
      "/bleep_audio/synthdefs/submarine.txt",
      "/bleep_audio/synthdefs/supersaw.txt",
      "/bleep_audio/synthdefs/voxhumana.txt",
    ];
  }

  idempotentInit() {
    if (!this.#started) {
      this.#audio_context = new AudioContext();
      this.#initial_audio_context_time_s = this.#audio_context.currentTime;
      this.#base_audio_context_time_s =
        this.#initial_audio_context_time_s + this.#audio_context.baseLatency;
      this.#initial_wallclock_time_s = Date.now() / 1000;
      this.#started = true;

      this.#default_synthdef_paths.map((x) => {
        this.#fetchFileAsString(x).then((synthdef) => {
          this.loadSynthDef(synthdef);
        });
      });
      this.initEffects();
    }
  }

  async initEffects() {
    this.#reverb = new Reverb(this.#audio_context,this.#monitor);
    await this.#reverb.load("large-hall.wav");
    this.#chorus = new RolandChorus(this.#audio_context,this.#monitor);
    this.#delay = new StereoDelay(this.#audio_context,this.#monitor);
  }

  hasStarted() {
    return this.#started;
  }

  triggerSample(time, sample_name, output_node_id, opts) {
    let buf = null;

    if (this.#loaded_buffers.has(sample_name)) {
      buf = this.#loaded_buffers.fetch(sample_name);
      this.#triggerBuffer(time, buf, output_node_id, opts);
    } else {
      this.#fetchAudioBuffer(`/bleep_audio/samples/${sample_name}.flac`).then(
        (response) => {
          this.#triggerBuffer(time, response, output_node_id, opts);
        }
      );
    }
  }

  #triggerBuffer(time, buffer, output_node_id, opts) {
    const delta_s = time - this.#initial_wallclock_time_s + 0.2;
    const audio_context_sched_s = this.#base_audio_context_time_s + delta_s; //- this.audio_context.baseLatency

    let source = this.#audio_context.createBufferSource();
    let gain = this.#audio_context.createGain();
    gain.gain.value = 1;
    source.connect(gain);
    source.buffer = buffer;

    // TODO consider whether the audio output should be
    // parameterised and used here (ouput_node_id)
    gain.connect(this.#audio_context.destination);
    source.start(audio_context_sched_s);

    // TODO perhaps set a timer here to disconnect the gain
    // and set things to null when the buffer has completed
    // playback

    // also need to register lifecycle with monitor
  }

  triggerOneshotSynth(time, synthdef_id, output_node_id, opts) {
    //alert("oneshot...")
    const delta_s = time - this.#initial_wallclock_time_s + 0.2;
    const audio_context_sched_s = this.#base_audio_context_time_s + delta_s; //- this.audio_context.baseLatency
        
    // POSSIBLE BUG 
    // Is this what you intended? 0 is a false value in javascript
    // so if opts.level is 0 it gets set back to 0.2 here 

    const note = opts.note || 60;
    const level = opts.level || 0.2;
    const duration = opts.duration || 1; // duration in seconds

    const pitchHz = 440 * Math.pow(2, (note - 69) / 12.0);

    console.log(`note is ${note}`);

    // demo of how to create effects

    const fx = new EffectsChain(this.#audio_context,this.#monitor);
    fx.add(this.#reverb);
    //fx.addParallel(this.#chorus,0.5);
    //fx.addSerial(this.#delay,0.5);
    opts.sendLevel = 0.5;

    // create a player, passing in the fx chain
    // we pass the fx chain so that it can be disposed of when we finish playing

    const gen = this.#getSynthGen(synthdef_id);
    let synth = new Player(
      this.#audio_context,
      gen,
      pitchHz,
      level,
      duration,
      fx,
      opts,
      this.#monitor
    );

    // TODO consider whether the audio output should be
    // parmaterised and used here (ouput_node_id)

    // dry pathway

    synth.out.connect(this.#audio_context.destination);

    // play the note

    synth.play(audio_context_sched_s);

    //this.#reverb.stop();
    //this.#chorus.stop();
    //this.#delay.stop();
    //this.fx.stop();

  }

  loadSynthDef(synthdef) {
    //create Synth for synthdef
    let grammar = new Grammar();
    let synthdef_json = grammar.parseStandard(synthdef);
    const gen = new Generator(synthdef_json);
    this.#loaded_synthgens.set(gen.shortname, gen);
    return gen.id;
  }

  jsonDispatch(json) {
    switch (json.cmd) {
      case "triggerOneshotSynth":
        this.triggerOneshotSynth(
          json.time,
          json.synthdef_id,
          json.output_node_id,
          json.opts
        );
        break;
      case "triggerSample":
        this.triggerSample(
          json.time,
          json.sample_name,
          json.output_node_id,
          json.opts
        );
        break;

      default:
        console.log(`Bleep Audio Core - dispatch method unknown ${json.cmd}`);
    }
  }

  #getSynthGen(synthdef_id) {
    if (this.#loaded_synthgens.has(synthdef_id)) {
      let sd = this.#loaded_synthgens.get(synthdef_id);
      return sd;
    } else {
      throw new Error(`SynthDef not found with id: ${synthdef_id}`);
    }
  }

  async #fetchAudioBuffer(filePath) {
    try {
      const response = await fetch(filePath);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      const abuf = await response.arrayBuffer();
      const buf = await this.#audio_context.decodeAudioData(abuf);
      return buf;
    } catch (error) {
      console.error("Failed to fetch the audio file:", error);
      return null;
    }
  }

  async #fetchFileAsString(filePath) {
    try {
      const response = await fetch(filePath);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      const text = await response.text();
      return text;
    } catch (error) {
      console.error("Failed to fetch the file:", error);
      return "";
    }
  }
}

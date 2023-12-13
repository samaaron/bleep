import Monitor from "./monitor";
import Generator from "./generator";
import Player from "./player";
import Grammar from "./grammar";
import { Reverb, RolandChorus, StereoDelay, DefaultFX } from "./effects";
import Utility from "./utility";

export default class BleepAudioCore {
  #audio_context;
  #monitor;
  #default_fx;
  #loaded_synthgens = new Map();
  #loaded_buffers = new Map();
  #running_fx = new Map();
  #initial_audio_context_time_s = 0;
  #base_audio_context_time_s = 0;
  #initial_wallclock_time_s = 0;
  #started = false;
  #default_synthdef_paths;

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

      this.#default_fx = new DefaultFX(this.#audio_context, this.#monitor);
      this.#default_fx.out.connect(this.#audio_context.destination);
    }
  }

  hasStarted() {
    return this.#started;
  }

  triggerFX(time, fx_name, id, output_id, opts) {
    let output_node = this.#resolveOutputId(output_id);
    let fx;

    // I think we need to be able to trigger at a specific time not just 'now'
    // Obvs also need to change fx here..
    switch (fx_name) {
      case "stereo_delay":
        fx = new StereoDelay(this.#audio_context, this.#monitor);
        break;
      case "reverb":
        fx = new Reverb(this.#audio_context, this.#monitor);
        fx.load("large-hall.wav");
        break;
      case "roland_chorus":
        fx = new RolandChorus(this.#audio_context, this.#monitor);
        break;
      default:
        console.log(`unknown FX name ${fx_name}`);
        fx = nil;
    }

    this.#running_fx.set(id, fx);
    fx.out.connect(output_node.in);
  }

  releaseFX(id) {
    if (this.#running_fx.has(id)) {
      const fx = this.#running_fx.get(id);
      this.#running_fx.delete(id);
      fx.stop();
    }
  }

  triggerSample(time, sample_name, output_id, opts) {
    let output_node = this.#resolveOutputId(output_id);
    let buf = null;

    if (this.#loaded_buffers.has(sample_name)) {
      buf = this.#loaded_buffers.fetch(sample_name);
      this.#triggerBuffer(time, buf, output_node, opts);
    } else {
      this.#fetchAudioBuffer(`/bleep_audio/samples/${sample_name}.flac`).then(
        (response) => {
          this.#triggerBuffer(time, response, output_node, opts);
        }
      );
    }
  }

  #resolveOutputId(output_id) {
    let output_node;
    if (output_id == "default") {
      output_node = this.#default_fx;
    } else {
      output_node = this.#running_fx.get(output_id);
    }
    return output_node;
  }

  #triggerBuffer(time, buffer, output_node, opts) {
    const delta_s = time - this.#initial_wallclock_time_s + 0.2;
    const audio_context_sched_s = this.#base_audio_context_time_s + delta_s; //- this.audio_context.baseLatency

    let source = this.#audio_context.createBufferSource();
    let gain = this.#audio_context.createGain();
    gain.gain.value = 1;
    source.connect(gain);
    source.buffer = buffer;

    // TODO consider whether the audio output should be
    // parameterised and used here (ouput_node_id)
    gain.connect(output_node.in);
    source.start(audio_context_sched_s);

    // TODO perhaps set a timer here to disconnect the gain
    // and set things to null when the buffer has completed
    // playback

    // also need to register lifecycle with monitor
  }

  triggerOneshotSynth(time, synthdef_id, output_id, opts) {
    let output_node = this.#resolveOutputId(output_id);
    const delta_s = time - this.#initial_wallclock_time_s + 0.2;
    const audio_context_sched_s = this.#base_audio_context_time_s + delta_s; //- this.audio_context.baseLatency

    const note = opts.hasOwnProperty("note") ? opts.note : 60;
    const level = opts.hasOwnProperty("level") ? opts.level : 0.2;
    const duration = opts.hasOwnProperty("duration") ? opts.duration : 0.5; // duration in seconds

    const pitchHz = Utility.midiNoteToHz(note);

    // demo of how to create effects
    // const fx = new EffectsChain(this.#audio_context, this.#monitor);

    //fx.add(this.#reverb, 0.05, 0.8);

    //this.#chorus.rate = 2.2;
    //this.#chorus.depth = 2;
    //this.#chorus.spread = 0.95;

    //this.#delay.leftDelay = 0.25;
    //this.#delay.rightDelay = 0.75;
    //this.#delay.feedback = 0.2;

    // the second parameter is the mix level (0 = fully dry, 1 = fully wet)
    // the third parameter controls the output level of this effect (and hence the remainder of the chain)
    // which is useful to stop amplitudes getting too big (which leads to crackles and clicks)

    //fx.add(this.#delay, 0.3, 0.8);
    //fx.add(this.#chorus, 0.2, 0.8);
    //fx.add(this.#reverb, 0.2, 0.8);

    // here we've made global effects, and I think we'll want to do this for reverb since
    // convolution is expensive
    // the others (delay, chorus) are cheaper to run and could be created for each note if we dont
    // want them shared, e.g.
    // fx.add(new RolandChorus(),0.2,0.8) etc etc

    // create a player, passing in the fx chain
    // we pass the fx chain so that it can be disposed of when we finish playing
    // if fx is undefined then the output of the synth is patched directly to player.out

    const gen = this.#getSynthGen(synthdef_id);
    let synth = new Player(
      this.#audio_context,
      gen,
      pitchHz,
      level,
      duration,
      opts,
      this.#monitor
    );

    // TODO consider whether the audio output should be
    // parmaterised and used here (ouput_node_id)

    // connect the synth player
    synth.out.connect(output_node.in);
    // play the note
    synth.play(audio_context_sched_s);

    // after the note has played the effects chain (but not any global effects it contains)
    // is disposed, after a delay that lets delays run out and reverb tails finish
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
          json.output_id,
          json.opts
        );
        break;
      case "triggerSample":
        this.triggerSample(
          json.time,
          json.sample_name,
          json.output_id,
          json.opts
        );
        break;
      case "triggerFX":
        this.triggerFX(
          json.time,
          json.fx_id,
          json.uuid,
          json.output_id,
          json.opts
        );
        break;
      case "releaseFX":
        this.releaseFX(json.time, json.uuid, json.opts);
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

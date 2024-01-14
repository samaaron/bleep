import Monitor from "./monitor";
import Generator from "./generator";
import Player from "./player";
import Grammar from "./grammar";
import { DefaultFX } from "./effects";
import { MonoDelay, StereoDelay } from "./delay";
import { RolandChorus } from "./chorus";
import { DeepPhaser, ThickPhaser, PicoPebble } from "./phaser";
import { Reverb, REVERB_FILENAME } from "./reverb";
import Utility from "./utility";
import { Flanger } from "./flanger";
import { AutoPan } from "./autopan";

export default class BleepAudioCore {
  #audio_context;
  #monitor;
  #default_fx;
  #loaded_synthgens = new Map();
  #loaded_buffers = new Map();
  #running_fx = new Map();
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
      "/bleep_audio/synthdefs/dogbass.txt",
      "/bleep_audio/synthdefs/dognoise.txt",
      "/bleep_audio/synthdefs/elpiano.txt",
      "/bleep_audio/synthdefs/filterwobble.txt",
      "/bleep_audio/synthdefs/fmbell.txt",
      "/bleep_audio/synthdefs/funkybass.txt",
      "/bleep_audio/synthdefs/hammond.txt",
      "/bleep_audio/synthdefs/ninth.txt",
      "/bleep_audio/synthdefs/noise.txt",
      "/bleep_audio/synthdefs/noisehat.txt",
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

  getAudioContext() {
    return this.#audio_context;
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
      case "auto_pan":
        fx = new AutoPan(this.#audio_context, this.#monitor);
        break;
      case "mono_delay":
        fx = new MonoDelay(this.#audio_context, this.#monitor);
        break;
      case "stereo_delay":
        fx = new StereoDelay(this.#audio_context, this.#monitor);
        break;
      case "flanger":
        fx = new Flanger(this.#audio_context, this.#monitor);
        break;
      case "deep_phaser":
        fx = new DeepPhaser(this.#audio_context, this.#monitor);
        break;
      case "thick_phaser":
        fx = new ThickPhaser(this.#audio_context, this.#monitor);
        break;
      case "pico_pebble":
        fx = new PicoPebble(this.#audio_context, this.#monitor);
        break;
      case "reverb":
      case "reverb_massive":
      case "reverb_large":
      case "reverb_medium":
      case "reverb_small":
      case "room_large":
      case "room_small":
      case "plate_drums":
      case "plate_vocal":
      case "plate_large":
      case "plate_small":
      case "ambience_large":
      case "ambience_medium":
      case "ambience_small":
      case "mic_reslo":
      case "mic_beyer":
      case "mic_foster":
      case "mic_lomo":
        fx = new Reverb(this.#audio_context, this.#monitor);
        fx.load(REVERB_FILENAME[fx_name]);
        break;
      case "roland_chorus":
        fx = new RolandChorus(this.#audio_context, this.#monitor);
        break;
      default:
        console.log(`unknown FX name ${fx_name}`);
        fx = nil;
    }

    this.#running_fx.set(id, fx);
    fx.setParams(opts, this.#audio_context.currentTime);
    fx.out.connect(output_node.in);
  }

  releaseFX(time, id) {
    if (this.#running_fx.has(id)) {
      const fx = this.#running_fx.get(id);
      this.#running_fx.delete(id);
      fx.stop();
    }
  }

  controlFX(time, id, params) {
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    if (this.#running_fx.has(id)) {
      const fx = this.#running_fx.get(id);
      fx.setParams(params, audio_context_sched_s);
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

  #clockTimeToAudioTime(wallclock_time_s) {
    const audio_time_s = this.#audio_context.currentTime;
    const clock_time_s = Date.now() / 1000;
    return (
      audio_time_s +
      (wallclock_time_s - clock_time_s) +
      this.#audio_context.baseLatency
    );
  }

  #triggerBuffer(time, buffer, output_node, opts) {
    // TODO : opts is always undefined @samaaron
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    let source = this.#audio_context.createBufferSource();
    // untested since opts isnt working yet - should set sample playback rate
    source.playbackRate.value = opts.rate !== undefined ? opts.rate : 1; // untested
    let gain = this.#audio_context.createGain();
    // untested since opts isn't working yet - should set the playback level of the sample
    gain.gain.value = opts.level !== undefined ? opts.level : 1; // untested
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
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);

    let output_node = this.#resolveOutputId(output_id);
    const note = opts.hasOwnProperty("note") ? opts.note : 60;
    const level = opts.hasOwnProperty("level") ? opts.level : 0.2;
    const duration = opts.hasOwnProperty("duration") ? opts.duration : 0.5; // duration in seconds
    const pitchHz = Utility.midiNoteToHz(note);

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
  }

  loadSynthDef(synthdef) {
    //create Synth for synthdef
    let grammar = new Grammar();
    let synthdef_json = grammar.parseStandard(synthdef);
    const gen = new Generator(synthdef_json);
    this.#loaded_synthgens.set(gen.shortname, gen);
    return gen.id;
  }

  jsonDispatch(time_delta_s, json) {
    switch (json.cmd) {
      case "triggerOneshotSynth":
        this.triggerOneshotSynth(
          json.time_s + time_delta_s,
          json.synthdef_id,
          json.output_id,
          json.opts
        );
        break;
      case "triggerSample":
        this.triggerSample(
          json.time_s + time_delta_s,
          json.sample_name,
          json.output_id,
          json.opts
        );
        break;
      case "triggerFX":
        this.triggerFX(
          json.time_s + time_delta_s,
          json.fx_id,
          json.uuid,
          json.output_id,
          json.opts
        );
        break;
      case "controlFX":
        this.controlFX(json.time_s + time_delta_s, json.uuid, json.opts);
        break;
      case "releaseFX":
        this.releaseFX(json.time_s + time_delta_s, json.uuid);
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

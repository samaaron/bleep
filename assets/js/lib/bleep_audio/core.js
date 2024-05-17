import BleepBufferCache from "./buffer_cache";
import Generator from "./generator";
import GrainPlayer from "./grainplayer";
import Grammar from "./grammar";

import Monitor from "./monitor";
import Player from "./player";
import Sampler from "./sampler";
import Utility from "./utility";
import { FinalMix } from "./final_mix";
import { AutoPan } from "./autopan";
import { Compressor } from "./compressor";
import { DeepPhaser, ThickPhaser, PicoPebble } from "./phaser";
import { Distortion, Overdrive } from "./distortion";
import { Flanger } from "./flanger";
import { MonoDelay, StereoDelay } from "./delay";
import { Reverb, REVERB_FILENAME } from "./reverb";
import { RolandChorus } from "./chorus";

export default class BleepAudioCore {
  #audio_context;
  #monitor;
  #main_out;
  #loaded_synthgens = new Map();
  #running_fx = new Map();
  #started = false;
  #default_synthdef_paths;
  #buffer_cache = new BleepBufferCache();

  constructor() {
    this.#monitor = new Monitor();

    this.#default_synthdef_paths = [
      "/bleep_audio/synthdefs/bansuri.txt",
      "/bleep_audio/synthdefs/bishi-bass.txt",
      "/bleep_audio/synthdefs/bishi-wobble.txt",
      "/bleep_audio/synthdefs/brasspad.txt",
      "/bleep_audio/synthdefs/breton.txt",
      "/bleep_audio/synthdefs/buzzer.txt",
      "/bleep_audio/synthdefs/catholicstyle.txt",
      "/bleep_audio/synthdefs/childhood.txt",
      "/bleep_audio/synthdefs/choir.txt",
      "/bleep_audio/synthdefs/default.txt",
      "/bleep_audio/synthdefs/dogbass.txt",
      "/bleep_audio/synthdefs/dognoise.txt",
      "/bleep_audio/synthdefs/elpiano.txt",
      "/bleep_audio/synthdefs/filterwobble.txt",
      "/bleep_audio/synthdefs/fmbell.txt",
      "/bleep_audio/synthdefs/funkybass.txt",
      "/bleep_audio/synthdefs/hammond.txt",
      "/bleep_audio/synthdefs/highnoise.txt",
      "/bleep_audio/synthdefs/ninth.txt",
      "/bleep_audio/synthdefs/noise.txt",
      "/bleep_audio/synthdefs/noisehat.txt",
      "/bleep_audio/synthdefs/pantest.txt",
      "/bleep_audio/synthdefs/pluck.txt",
      "/bleep_audio/synthdefs/randomblips.txt",
      "/bleep_audio/synthdefs/rolandtb.txt",
      "/bleep_audio/synthdefs/saveaprayer.txt",
      "/bleep_audio/synthdefs/sawlead.txt",
      "/bleep_audio/synthdefs/simplepulse.txt",
      "/bleep_audio/synthdefs/subbass.txt",
      "/bleep_audio/synthdefs/submarine.txt",
      "/bleep_audio/synthdefs/supersaw.txt",
      "/bleep_audio/synthdefs/sweepbass.txt",
      "/bleep_audio/synthdefs/tanpura.txt",
      "/bleep_audio/synthdefs/thickbass.txt",
      "/bleep_audio/synthdefs/voxhumana.txt",
    ];
  }

  idempotentInitAudio() {
    if (!this.#started) {
      this.#audio_context = new AudioContext();
      this.#started = true;

      this.#default_synthdef_paths.map((x) => {
        this.#fetchFileAsString(x).then((synthdef) => {
          this.loadSynthDef(synthdef);
        });
      });

      this.#main_out = new FinalMix(this.#audio_context, this.#monitor);
      this.#main_out.out.connect(this.#audio_context.destination);
    }
  }

  getAudioContext() {
    return this.#audio_context;
  }

  hasStarted() {
    return this.#started;
  }

  idempotentStartFinalMix(output_id) {
    if (!this.#running_fx.has(output_id)) {
      this.startFinalMix(output_id);
    }
  }

  startFinalMix(output_id) {
    const fx = new FinalMix(this.#audio_context, this.#monitor);
    this.#running_fx.set(output_id, fx);
    fx.out.connect(this.#main_out.in);
  }

  restartFinalMix(output_id) {
    if (this.#running_fx.has(output_id)) {
      const fx = this.#running_fx.get(output_id);
      this.#running_fx.delete(output_id);
      fx.gracefulStop();
      this.startFinalMix(output_id);
    }
  }

  restartMainOut() {
    this.#main_out.gracefulStop();
    this.#main_out = new FinalMix(this.#audio_context, this.#monitor);
    this.#main_out.out.connect(this.#audio_context.destination);
    setTimeout(() => {
      this.#running_fx.forEach((fx) => {
        fx.stop();
      });
      this.#running_fx.clear();
    }, 500);


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
      case "compressor":
        fx = new Compressor(this.#audio_context, this.#monitor);
        break;
      case "distortion":
        fx = new Distortion(this.#audio_context, this.#monitor);
        break;
      case "overdrive":
        fx = new Overdrive(this.#audio_context, this.#monitor);
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
      case "ambience_gated":
      case "mic_reslo":
      case "mic_beyer":
      case "mic_foster":
      case "mic_lomo":
        fx = new Reverb(this.#audio_context, this.#monitor, this.#buffer_cache);
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
    console.log("triggering sample", sample_name, output_id, opts);
    const sample_path = `/bleep_audio/samples/${sample_name}.flac`;
    const output_node = this.#resolveOutputId(output_id);
    this.#buffer_cache
      .load_buffer(sample_path, this.#audio_context)
      .then((buf) => {
        this.#triggerBuffer(time, buf, output_node, opts);
      });
  }

  triggerGrains(time, sample_name, output_id, opts) {
    console.log("triggering grains", sample_name, output_id, opts);
    const sample_path = `/bleep_audio/samples/${sample_name}.flac`;
    const output_node = this.#resolveOutputId(output_id);
    this.#buffer_cache
      .load_buffer(sample_path, this.#audio_context)
      .then((buf) => {
        this.#triggerGrainsFromBuffer(time, buf, output_node, opts);
      });
  }

  #resolveOutputId(output_id) {
    return this.#running_fx.get(output_id);
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

  // TODO #19 how to stop a sample player when loop is enabled - stop button has no effect currently and it runs forever

  #triggerBuffer(time, buffer, output_node, opts) {
    const sampler = new Sampler(
      this.#audio_context,
      this.#monitor,
      buffer,
      opts
    );
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    sampler.out.connect(output_node.in);
    sampler.play(audio_context_sched_s);

    //let source = this.#audio_context.createBufferSource();
    //source.playbackRate.value = opts.rate !== undefined ? opts.rate : 1;
    // added loop parameter to allow (infinite) looping of a clip
    //source.loop = opts.loop !== undefined ? opts.loop : false;
    //let gain = this.#audio_context.createGain();
    //gain.gain.value = opts.level !== undefined ? opts.level : 1;
    //source.connect(gain);
    //source.buffer = buffer;

    // TODO consider whether the audio output should be
    // parameterised and used here (ouput_node_id)
    //gain.connect(output_node.in);
    //source.start(audio_context_sched_s);

    // TODO perhaps set a timer here to disconnect the gain
    // @sam done - can be managed through onended function on source node
    // and set things to null when the buffer has completed
    // playback

    // also need to register lifecycle with monitor
    // @sam done
  }

  #triggerGrainsFromBuffer(time, buffer, output_node, opts) {
    const grain_player = new GrainPlayer(this.#audio_context, buffer, opts);
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    grain_player.out.connect(output_node.in);
    grain_player.play(audio_context_sched_s);

    //let source = this.#audio_context.createBufferSource();
    //source.playbackRate.value = opts.rate !== undefined ? opts.rate : 1;
    //let gain = this.#audio_context.createGain();
    //gain.gain.value = opts.level !== undefined ? opts.level : 1;
    //source.connect(gain);
    //source.buffer = buffer;
    //gain.connect(output_node.in);
    //source.start(audio_context_sched_s);
  }

  triggerOneShotSynth(time, synthdef_id, output_id, opts) {
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

    // todo: should these be const?
    const grammar = new Grammar();
    const synthdef_json = grammar.parseStandard(synthdef);
    const gen = new Generator(synthdef_json);
    this.#loaded_synthgens.set(gen.shortname, gen);
    return gen.id;
  }

  jsonDispatch(adjusted_time_s, json) {
    switch (json.cmd) {
      case "triggerOneShotSynth":
        this.triggerOneShotSynth(
          adjusted_time_s,
          json.synthdef_id,
          json.output_id,
          json.opts
        );
        break;
      case "triggerSample":
        this.triggerSample(
          adjusted_time_s,
          json.sample_name,
          json.output_id,
          json.opts
        );
        break;
      case "triggerGrains":
        this.triggerGrains(
          adjusted_time_s,
          json.sample_name,
          json.output_id,
          json.opts
        );
        break;
      case "triggerFX":
        this.triggerFX(
          adjusted_time_s,
          json.fx_id,
          json.uuid,
          json.output_id,
          json.opts
        );
        break;
      case "controlFX":
        this.controlFX(adjusted_time_s, json.fx_id, json.opts);
        break;
      case "releaseFX":
        this.releaseFX(adjusted_time_s, json.fx_id);
        break;

      default:
        console.log(`Bleep Audio Core - dispatch method unknown: ${json.cmd}`);
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

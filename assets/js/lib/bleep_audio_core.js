import BleepSynthEngine from "../../vendor/bleep-synth/bleepsynth/core/bleep_synth_engine";
import BleepSynthEngineConstants from "../../vendor/bleep-synth/bleepsynth/core/constants";
import BleepAnalyser from "./bleep_analyser";

export default class BleepAudioCore {
  #audio_context;
  #audio_engine;
  #main_out;
  #running_fx = new Map();
  #started = false;
  #init_promise = null;

  constructor() {
  }

  async idempotentInitAudio() {
    if (this.#started) {
      await this.#init_promise;
      return;
    }

    this.#started = true;
    this.#init_promise = new Promise(async (resolve, reject) => {
      try {
        this.#audio_context = new AudioContext();
        this.#audio_engine = new BleepSynthEngine(
          this.#audio_context,
          "/bleep-synth-assets"
        );
        this.#main_out = this.#audio_engine.createFinalMix();
        this.#main_out.out.connect(this.#audio_context.destination);
        this.#main_out.setGain(0.8);
        await this.#audio_engine.loadPresetSynthDefs();
        console.log("loaded synthdefs");
        resolve();
      } catch (error) {
        console.error("Error during audio initialization", error);
        reject(error);
      }
    });

    await this.#init_promise;
  }

  setVolume(vol) {
    this.#main_out.setGain(vol, this.#audio_context.currentTime);
  }

  getAudioContext() {
    return this.#audio_context;
  }

  idempotentStartFinalMix(output_id) {
    if (!this.#running_fx.has(output_id)) {
      return this.startFinalMix(output_id);
    } else {
      return null;
    }
  }

  startFinalMix(output_id) {
    const fx = this.#audio_engine.createFinalMix();
    this.#running_fx.set(output_id, fx);
    fx.out.connect(this.#main_out.in);
    return fx;
  }

  stopFinalMix(output_id) {
    if (this.#running_fx.has(output_id)) {
      const fx = this.#running_fx.get(output_id);
      this.#running_fx.delete(output_id);
      fx.gracefulStop();
    }
  }

  restartMainOut() {
    this.#main_out.gracefulStop();
    this.#main_out = this.#audio_engine.createFinalMix();
    this.#main_out.out.connect(this.#audio_context.destination);
    setTimeout(() => {
      this.#running_fx.forEach((fx) => {
        fx.stop();
      });
      this.#running_fx.clear();
    }, 500);
  }

  triggerFX(time, fx_name, id, output_id, opts) {
    try {
      let output_node = this.#resolveOutputId(output_id);
      const fx = this.#audio_engine.createEffect(fx_name);
      this.#running_fx.set(id, fx);
      fx.setParams(opts, this.#audio_context.currentTime);
      fx.out.connect(output_node.in);
    } catch (error) {
      console.error("Error triggering FX", error);
    }
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

  loadSample(sample_name) {
    this.#audio_engine.loadSample(sample_name);
    console.log("cached sample", sample_name);
  }

  preloadFX(fx_name) {
    // Preload impulse responses
    if (BleepSynthEngineConstants.REVERB_IMPULSES.hasOwnProperty(fx_name)) {
      this.loadImpulse(fx_name);
    }
  }

  loadImpulse(reverb_name) {
    this.#audio_engine.loadImpulse(reverb_name);
  }

  triggerSample(time, sample_name, output_id, opts) {
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    console.log("triggering sample", sample_name, output_id, opts);
    const output_node = this.#resolveOutputId(output_id);
    this.#audio_engine.playSample(
      audio_context_sched_s,
      sample_name,
      output_node.in,
      opts
    );
  }

  triggerGrains(time, sample_name, output_id, opts) {
    const audio_context_sched_s = this.#clockTimeToAudioTime(time);
    console.log("triggering grains", sample_name, output_id, opts);

    const output_node = this.#resolveOutputId(output_id);
    this.#audio_engine.playGrains(
      audio_context_sched_s,
      sample_name,
      output_node.in,
      opts
    );
  }

  createNodeAnalyser(audio_node) {
    return new BleepAnalyser(this.#audio_context, audio_node);
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

  triggerOneShotSynth(time, synthdef_id, output_id, opts) {
    // const t2 = this.#audio_context.currentTime;
    // console.log(`time diff: ${time - t2}`)
    try {
      const audio_context_sched_s = this.#clockTimeToAudioTime(time);

      let output_node = this.#resolveOutputId(output_id);

      const note = opts.hasOwnProperty("note") ? opts.note : 60;

      const pitchHz = 440 * Math.pow(2, (note - 69) / 12.0);
      const default_opts = { level: 0.2, duration: 0.5, pitch: pitchHz };
      const synth = this.#audio_engine.createPlayer(synthdef_id, {
        ...default_opts,
        ...opts,
      });

      // connect the synth player
      synth.out.connect(output_node.in);
      // play the note
      synth.play(audio_context_sched_s);
    } catch (error) {
      console.error("Error triggering synth", error);
    }
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
          json.fx_name,
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
}

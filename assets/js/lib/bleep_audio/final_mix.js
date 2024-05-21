import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Final Global Effect Chain for the Bleep Machine
 */
export class FinalMix extends BleepEffect {
  static DEFAULT_GAIN = 1;

  _gain;
  _analyser;
  _running;
  _scope_data;
  _scope_buffer;

  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._gain = new GainNode(ctx, {
      gain: FinalMix.DEFAULT_GAIN,
    });

    this._analyser = ctx.createAnalyser();
    this._analyser.fftSize = 2048 ;

    this._scope_data = new Uint8Array(this._analyser.frequencyBinCount);
    this._scope_buffer = ctx.createBuffer(
      1,
      this._scope_data.length,
      ctx.sampleRate
    );
    console.log("scope_buffer", this._scope_buffer);
    this._gain = ctx.createGain();
    this._gain.gain.value = 1;
    this._gain.connect(this._analyser);
    this._running = true;
  }

  get in() {
    return this._gain;
  }

  get out() {
    return this._gain;
  }

  setGain(g, when) {
    if (this._running) {
      this._gain.gain.setValueAtTime(g, when);
    }
  }

  setParams(params, when) {
    if (this._running) {
      super.setParams(params, when);
      if (typeof params.gain !== "undefined") {
        this.setGain(params.gain, when);
      }
    }
  }

  gracefulStop() {
    this._running = false;
    const currentTime = this._context.currentTime;
    this._gain.gain.setValueAtTime(this._gain.gain.value, currentTime);
    this._gain.gain.linearRampToValueAtTime(0, currentTime + 0.5);
    setTimeout(() => {
      this.stop();
    }, 500);
  }

  stop() {
    super.stop();
    this._gain.disconnect();
    this._gain = null;
  }

  getScopeData() {
    this._analyser.getByteTimeDomainData(this._scope_data);
    const data = this._scope_buffer.getChannelData(0);

    // Copy the data from the Uint8Array to the AudioBuffer
    for (let i = 0; i < this._scope_data.length; i++) {
      data[i] = (this._scope_data[i] - 128) / 128;
    }
    return this._scope_buffer;
  }
}

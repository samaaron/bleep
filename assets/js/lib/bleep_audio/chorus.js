import { VERBOSE } from "./constants";
import Utility from "./utility";
import { BleepEffect } from "./effects";

// ----------------------------------------------------------------
// RolandChorus - chorus unit based on Roland Juno circuit
// controls for depth, rate and stereo spread
// ----------------------------------------------------------------

export class RolandChorus extends BleepEffect {

  static DEFAULT_CHORUS_RATE = 0.8;
  static DEFAULT_STEREO_SPREAD = 0.8;
  static DEFAULT_CHORUS_DEPTH = 0.1;
  static DEFAULT_DELAY_TIME = 0.0035;

  _lfo;
  _leftDelay;
  _rightDelay;
  _leftPan;
  _rightPan;
  _leftGain;
  _rightGain;
  _leftMix;
  _rightMix;

  /**
   * Creates an instance of RolandChorus.
   * @param {AudioContext} ctx - The audio context for the chorus effect.
   * @param {Monitor} monitor - The monitor object to track the chorus effect.
   */
  constructor(ctx, monitor) {
    if (VERBOSE) console.log("Making a Chorus");
    super(ctx, monitor);
    this.#makeGains();
    this.#makeDelayLines();
    this.#makeLFO();
    this.#makeConnections();
    this._lfo.start();
  }

  /**
   * Make various gain stages
   */
  #makeGains() {
    // depth controls
    this._leftGain = new GainNode(this._context, {
      gain: RolandChorus.DEFAULT_CHORUS_DEPTH / 1000
    });
    this._rightGain = new GainNode(this._context, {
      gain: -RolandChorus.DEFAULT_CHORUS_DEPTH / 1000
    });
    // left and right mixers
    this._leftMix = new GainNode(this._context, {
      gain: 0.5
    });
    this._rightMix = new GainNode(this._context, {
      gain: 0.5
    });
  }

  /**
   * Make the LFO that controls the delay time
   */
  #makeLFO() {
    this._lfo = new OscillatorNode(this._context, {
      type: "triangle",
      frequency: RolandChorus.DEFAULT_CHORUS_RATE,
    });
  }

  /**
   * Make left and right delay lines
   */
  #makeDelayLines() {
    // left delay line
    this._leftDelay = new DelayNode(this._context, {
      delayTime: RolandChorus.DEFAULT_DELAY_TIME
    });
    this._leftPan = new StereoPannerNode(this._context, {
      pan: -RolandChorus.DEFAULT_STEREO_SPREAD
    });
    // right delay line
    this._rightDelay = new DelayNode(this._context, {
      delayTime: RolandChorus.DEFAULT_DELAY_TIME
    });
    this._rightPan = new StereoPannerNode(this._context, {
      pan: RolandChorus.DEFAULT_STEREO_SPREAD
    });
  }

  /**
   * Wire everything together
   */
  #makeConnections() {
    // connect left delay line
    this._wetGain.connect(this._leftDelay);
    this._leftDelay.connect(this._leftMix);
    this._wetGain.connect(this._leftMix);
    this._leftMix.connect(this._leftPan);
    this._leftPan.connect(this._out);
    // connect right delay line
    this._wetGain.connect(this._rightDelay);
    this._rightDelay.connect(this._rightMix);
    this._wetGain.connect(this._rightMix);
    this._rightMix.connect(this._rightPan);
    this._rightPan.connect(this._out);
    // connect gains on LFO to control depth
    this._lfo.connect(this._leftGain);
    this._lfo.connect(this._rightGain);
    this._leftGain.connect(this._leftDelay.delayTime);
    this._rightGain.connect(this._rightDelay.delayTime);
  }

  /**
   * Calculates the time it takes for the chorus effect to fade out.
   * @returns {number} The estimated fade out time.
   */
  timeToFadeOut() {
    // delay line is very short for a chorus, this will cover it
    return 0.05;
  }

  /**
   * Sets the depth of the chorus effect. Depth controls the intensity of the modulation.
   * @param {number} d - The depth value, typically between 0 and 1.
   * @param {number} when - the time at which the change should occur
   */
  setDepth(d, when) {
    this._leftGain.gain.setValueAtTime(d / 1000, when); // normal phase on left ear
    this._rightGain.gain.setValueAtTime(-d / 1000, when); // phase invert on right ear
  }

  /**
   * Sets the stereo spread of the chorus effect. Spread controls the stereo separation of the effect.
   * @param {number} s - The spread value, typically between 0 (mono) and 1 (full stereo).
   * @param {number} when - the time at which the change should occur
   */
  setSpread(s, when) {
    this._leftPan.pan.setValueAtTime(-s, when);
    this._rightPan.pan.setValueAtTime(s, when);
  }

  /**
  * Sets the rate of the chorus effect. Rate controls the speed of the modulation.
  * @param {number} r - The rate value in Hz, between 0.01 and 15.
  * @param {number} when - the time at which the change should occur
  */
  setRate(r, when) {
    this._lfo.frequency.setValueAtTime(Utility.clamp(r, 0.01, 15), when);
  }

  /**
   * set ths parameters for the effect
   * @param {object} params - key value list of parameters
   * @param {number} when - the time at which the change should occur
   */
  setParams(params, when) {
    super.setParams(params, when);
    if (typeof params.depth !== "undefined") {
      this.setDepth(params.depth, when);
    }
    if (typeof params.spread !== "undefined") {
      this.setSpread(params.spread, when);
    }
    if (typeof params.rate !== "undefined") {
      this.setRate(params.rate, when);
    }
  }

  /**
   * Stops the chorus effect and cleans up resources.
   */
  stop() {
    super.stop();
    this._lfo.stop();
    this._leftDelay.disconnect();
    this._leftDelay = null;
    this._rightDelay.disconnect();
    this._rightDelay = null;
    this._leftPan.disconnect();
    this._leftPan = null;
    this._rightPan.disconnect();
    this._rightPan = null;
    this._leftGain.disconnect();
    this._leftGain = null;
    this._rightGain.disconnect();
    this._rightGain = null;
    this._leftMix.disconnect();
    this._leftMix = null;
    this._rightMix.disconnect();
    this._rightMix = null;
  }
}

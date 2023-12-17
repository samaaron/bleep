import Monitor from "./monitor";
import Utility from "./utility";

const VERBOSE = true;

// Not sure why this is needed - haven't inluded in the inheritance hierarchy below

export class DefaultFX {
  #context;
  #monitor;
  #gain;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#monitor = monitor;
    this.#monitor.retain("default_fx");
    this.#gain = ctx.createGain();
    this.#gain.gain.value = 1;
  }

  get in() {
    return this.#gain;
  }

  get out() {
    return this.#gain;
  }

  stop() {
    this.#gain.disconnect();
    this.#gain = null;
    this.#monitor.release("default_fx");
  }
}

// Abstract case class (not exported)

class BleepEffect {

  static DEFAULT_WET_LEVEL = 0.2
  static DEFAULT_DRY_LEVEL = 1

  _context;
  _monitor;
  _wetGain
  _dryGain
  _in
  _out

  /**
   * Creates an instance of Bleep effect (abstract class)
   * @param {AudioContext} ctx - The audio context  
   * @param {Monitor} monitor - The monitor object 
   */
  constructor(ctx, monitor) {
    this._context = ctx;
    this._monitor = monitor;
    this._monitor.retain(this.constructor.name);
    this._wetGain = new GainNode(ctx, {
      gain: BleepEffect.DEFAULT_WET_LEVEL
    });
    this._dryGain = new GainNode(ctx, {
      gain: BleepEffect.DEFAULT_DRY_LEVEL
    });
    this._in = new GainNode(ctx, {
      gain: 1
    });
    this._out = new GainNode(ctx, {
      gain: 1
    });
    // connect wet and dry signal paths
    this._in.connect(this._wetGain);
    this._in.connect(this._dryGain);
    this._dryGain.connect(this._out);
  }

  /**
   * get the input node
   */
  get in() {
    return this._in;
  }

  /**
   * get the output node
   */
  get out() {
    return this._out;
  }

  /**
   * stop the effect and dispose of objects
   */
  stop() {
    this._monitor.release(this.constructor.name);
    this._context = null;
    this._monitor = null;
    this._in.disconnect();
    this._in = null;
    this._out.disconnect();
    this._out = null;
    this._wetGain.disconnect();
    this._wetGain = null;
    this._dryGain.disconnect();
    this._dryGain = null;
  }

  /**
   * set ths parameters for the effect
   * @param {object} params - key value list of parameters
   * @param {number} when - the time at which the change should occur
   */
  setParams(params, when) {
    if (typeof params.wetLevel !== "undefined")
      this.setWetLevel(params.wetLevel, when);
    if (typeof params.dryLevel !== "undefined")
      this.setDryLevel(params.dryLevel, when);
  }

  /**
   * set the wet level for the effect
   * @param {number} wetLevel - the gain of the wet signal pathway in the range [0,1]
   * @param {number} when - the time at which the change should occur
   */
  setWetLevel(wetLevel, when) {
    this._wetGain.gain.setValueAtTime(wetLevel,when);
  }

    /**
   * set the dry level for the effect
   * @param {number} dryLevel - the gain of the dry signal pathway in the range [0,1]
   * @param {number} when - the time at which the change should occur
   */
  setDryLevel(dryLevel, when) {
    this._dryGain.gain.setValueAtTime(dryLevel, when);
  }

  /**
   * return the time it takes for the effect to fade out - must be overriden
   */
  timeToFadeOut() {
    throw new Error("BleepEffect is abstract, you must implement this");
  }

}


// ----------------------------------------------------------------
// Reverb - convolutional reverb
// ----------------------------------------------------------------

export class Reverb extends BleepEffect {

  _isValid;
  _convolver;

  /**
   * Creates an instance of Reverb.
   * @param {AudioContext} ctx - The audio context for the reverb effect.
   * @param {Monitor} monitor - The monitor object to track the reverb effect.
   */
  constructor(ctx, monitor) {
    super(ctx, monitor);
    if (VERBOSE) console.log("Making a Reverb");
    this._isValid = false;
    this._convolver = new ConvolverNode(ctx);
    // connect everything up
    this._wetGain.connect(this._convolver);
    this._convolver.connect(this._out);
  }

  /**
   * Loads an impulse response from a file for the reverb effect.
   * @param {string} filename - The filename of the impulse response.
   */
  async load(filename) {
    const impulseResponse = await this.getImpulseResponseFromFile(filename);
    if (this._isValid) {
      this._convolver.buffer = impulseResponse;
    }
  }

  /**
   * Retrieves an impulse response from a file.
   * @param {string} filename - The filename of the impulse response.
   * @returns {AudioBuffer} The decoded audio data.
   */
  async getImpulseResponseFromFile(filename) {
    try {
      let reply = await fetch(`/bleep_audio/impulses/${filename}`);
      this._isValid = true;
      return this._context.decodeAudioData(await reply.arrayBuffer());
    } catch (err) {
      this._isValid = false;
      if (VERBOSE)
        console.log(
          "unable to load the impulse response file called " + filename
        );
    }
  }

  /**
   * Calculates the time it takes for an input signal to fade out.
   * @returns {number} The duration of the impulse response, representing fade out time.
   */
  timeToFadeOut() {
    // the time an input to this reverb takes to fade out is equal to the duration
    // of the impulse response used
    return this._convolver.buffer.duration;
  }

  /**
   * Stops the reverb effect and cleans up resources.
   */
  stop() {
    super.stop();
    this._convolver.disconnect();
    this._convolver = null;
  }
}

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
      gain: RolandChorus.DEFAULT_CHORUS_DEPTH/1000
    });
    this._rightGain = new GainNode(this._context, {
      gain: -RolandChorus.DEFAULT_CHORUS_DEPTH/1000
    });
    // left and right mixers
    this._leftMix = new GainNode(this._context,{
      gain:0.5
    });
    this._rightMix = new GainNode(this._context,{
      gain:0.5
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
  setSpread(s,when) {
    this._leftPan.pan.setValueAtTime(-s,when);
    this._rightPan.pan.setValueAtTime(s,when);
  }

  /**
  * Sets the rate of the chorus effect. Rate controls the speed of the modulation.
  * @param {number} r - The rate value in Hz, between 0.01 and 15.
  * @param {number} when - the time at which the change should occur
  */
  setRate(r,when) {
    this._lfo.frequency.setValueAtTime(Utility.clamp(r, 0.01, 15),when);
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

// ----------------------------------------------------------------
// StereoDelay
// stereo delay with feedback
// you can set different delay times for the left and right channels
// ----------------------------------------------------------------

export class StereoDelay extends BleepEffect {

  static LOWEST_AMPLITUDE = 0.05; // used to work out when the effect fades out
  static DEFAULT_SPREAD = 0.95;
  static DEFAULT_LEFT_DELAY = 0.25;
  static DEFAULT_RIGHT_DELAY = 0.5;
  static DEFAULT_FEEDBACK = 0.4;

  _leftDelay;
  _rightDelay;
  _leftPan;
  _rightPan;
  _leftFeedbackGain;
  _rightFeedbackGain;
  _maxFeedback;

  /**
   * Creates an instance of StereoDelay.
   * @param {AudioContext} ctx - The audio context for the delay effect.
   * @param {Monitor} monitor - The monitor object to track the delay effect.
   */
  constructor(ctx, monitor) {
    super(ctx,monitor);
    if (VERBOSE) console.log("Making a Delay");
    this.#makeDelayLines();
    this.#makeFeedbackPath();
    this.#makeConnections();
  }

  /**
   * Make the delay lines for left and right channels
   */
  #makeDelayLines() {
    // left delay
    this._leftDelay = new DelayNode(this._context, {
      delayTime: StereoDelay.DEFAULT_LEFT_DELAY
    });
    // pan it to the left
    this._leftPan = new StereoPannerNode(this._context, {
      pan: -StereoDelay.DEFAULT_SPREAD
    });
    // right delay
    this._rightDelay = new DelayNode(this._context, {
      delayTime: StereoDelay.DEFAULT_RIGHT_DELAY
    });
    // pan it to the right
    this._rightPan = new StereoPannerNode(this._context, {
      pan: StereoDelay.DEFAULT_SPREAD
    });
  }

  /**
   * Make the feedback pathway
   */
  #makeFeedbackPath() {
    this._maxFeedback = StereoDelay.DEFAULT_FEEDBACK;
    this._leftFeedbackGain = this._context.createGain();
    this._leftFeedbackGain.gain.value = StereoDelay.DEFAULT_FEEDBACK;
    this._rightFeedbackGain = this._context.createGain();
    this._rightFeedbackGain.gain.value = StereoDelay.DEFAULT_FEEDBACK;
  }

  /**
   * Wire everything up
   */
  #makeConnections() {
    // connect up left side
    this._wetGain.connect(this._leftDelay);
    this._leftDelay.connect(this._leftFeedbackGain);
    this._leftDelay.connect(this._leftPan);
    this._leftPan.connect(this._out);
    this._leftFeedbackGain.connect(this._leftDelay);
    // connect up right side
    this._wetGain.connect(this._rightDelay);
    this._rightDelay.connect(this._rightFeedbackGain);
    this._rightDelay.connect(this._rightPan);
    this._rightPan.connect(this._out);
    this._rightFeedbackGain.connect(this._rightDelay);
  }

  /**
   * Sets the stereo spread of the delay effect.
   * @param {number} s - The spread value, controlling the stereo separation.
   * @param {number} when - the time at which the change should occur
   */
  setSpread(s,when) {
    this._leftPan.pan.setValueAtTime(-s,when);
    this._rightPan.pan.setValueAtTime(s,when);
  }

  /**
   * Sets the delay time for the left channel.
   * @param {number} d - The delay time in seconds for the left channel.
   * @param {number} when - the time at which the change should occur
   */
  setLeftDelay(d,when) {
    this._leftDelay.delayTime.setValueAtTime(d,when);
  }

  /**
   * Sets the delay time for the right channel.
   * @param {number} d - The delay time in seconds for the right channel.
   * @param {number} when - the time at which the change should occur
   */
  setRightDelay(d,when) {
    this._rightDelay.delayTime.setValueAtTime(d,when);
  }

  /**
   * Sets the feedback amount for the delay effect.
   * @param {number} f - The feedback level, typically between 0 and 1.
   * @param {number} when - the time at which the change should occur
   */
  setFeedback(f,when) {
    // a subtle issue here - we could potentially change the feedback to a smaller value
    // at a future time, which would lead to the echoes being clipped
    // so keep track of the longest feedback we have ever set and use that for the decay calc
    if (f>this._maxFeedback) {
      this._maxFeedback = f;
    }
    this._leftFeedbackGain.gain.setValueAtTime(f,when);
    this._rightFeedbackGain.gain.setValueAtTime(f,when);
  }

  /**
   * Calculates the time it takes for the delay effect to fade out.
   * @returns {number} The estimated fade out time in seconds.
   */
  timeToFadeOut() {
    // work out how long the delay line will take to fade out (exponential decay)
    const m = Math.max(
      this._leftDelay.delayTime.value,
      this._rightDelay.delayTime.value
    );
    const n = Math.log(StereoDelay.LOWEST_AMPLITUDE) / Math.log(this._maxFeedback);
    return m * n;
  }

  /**
   * set ths parameters for the effect
   * @param {object} params - key value list of parameters
   * @param {number} when - the time at which the change should occur
   */
  setParams(params, when) {
    super.setParams(params, when);
    if (typeof params.leftDelay !== "undefined") {
      this.setLeftDelay(params.leftDelay, when);
    }
    if (typeof params.rightDelay !== "undefined") {
      this.setRightDelay(params.rightDelay, when);
    }
    if (typeof params.spread !== "undefined") {
      this.setSpread(params.spread, when);
    }
    if (typeof params.feedback !== "undefined") {
      this.setFeedback(params.feedback, when);
    }
  }

  /**
   * Stops the delay and cleans up.
   */
  stop() {
    this._leftDelay.disconnect();
    this._leftDelay = null;
    this._rightDelay.disconnect();
    this._rightDelay = null;
    this._leftPan.disconnect();
    this._leftPan = null;
    this._rightPan.disconnect();
    this._rightPan = null;
    this._leftFeedbackGain.disconnect();
    this._leftFeedbackGain = null;
    this._rightFeedbackGain.disconnect();
    this._rightFeedbackGain = null;
  }
}

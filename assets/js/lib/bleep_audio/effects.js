import Utility from "./utility";

const VERBOSE = true;

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

// ----------------------------------------------------------------
// Reverb - convolutional reverb
// ----------------------------------------------------------------

export class Reverb {
  #context;
  #monitor;
  #isValid;
  #convolver;

  /**
   * Creates an instance of Reverb.
   * @param {AudioContext} ctx - The audio context for the reverb effect.
   * @param {Object} monitor - The monitor object to track the reverb effect.
   */
  constructor(ctx, monitor) {
    if (VERBOSE) console.log("Making a Reverb");
    this.#context = ctx;
    this.#monitor = monitor;
    this.#isValid = false;
    // monitor
    this.#monitor.retain("reverb");
    this.#convolver = ctx.createConvolver();
  }

  /**
   * Loads an impulse response from a file for the reverb effect.
   * @param {string} filename - The filename of the impulse response.
   */
  async load(filename) {
    const impulseResponse = await this.getImpulseResponseFromFile(filename);
    if (this.#isValid) {
      this.#convolver.buffer = impulseResponse;
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
      this.#isValid = true;
      return this.#context.decodeAudioData(await reply.arrayBuffer());
    } catch (err) {
      this.#isValid = false;
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
    return this.#convolver.buffer.duration;
  }

  /**
   * Getter for the convolver input node.
   * @returns {ConvolverNode} The convolver node used as the input.
   */
  get in() {
    return this.#convolver;
  }

  /**
   * Getter for the convolver output node.
   * @returns {ConvolverNode} The convolver node used as the output.
   */
  get out() {
    return this.#convolver;
  }

  /**
   * Stops the reverb effect and cleans up resources.
   */
  stop() {
    this.#convolver.disconnect();
    this.#convolver = null;
    this.#monitor.release("reverb");
  }
}

// ----------------------------------------------------------------
// RolandChorus - chorus unit based on Roland Juno circuit
// controls for depth, rate and stereo spread
// ----------------------------------------------------------------

export class RolandChorus {
  static DEFAULT_CHORUS_RATE = 0.8;
  static DEFAULT_STEREO_SPREAD = 0.8;
  static DEFAULT_CHORUS_DEPTH = 0.001;
  static DEFAULT_DELAY_TIME = 0.0035;

  #in;
  #out;
  #lfo;
  #leftDelay;
  #rightDelay;
  #leftPan;
  #rightPan;
  #leftGain;
  #rightGain;
  #leftMix;
  #rightMix;
  #monitor;
  #context;

  /**
   * Creates an instance of RolandChorus.
   * @param {AudioContext} ctx - The audio context for the chorus effect.
   * @param {Object} monitor - The monitor object to track the chorus effect.
   */
  constructor(ctx, monitor) {
    if (VERBOSE) console.log("Making a Chorus");
    this.#context = ctx;
    this.#monitor = monitor;
    this.#monitor.retain("chorus");
    this.#makeGains();
    this.#makeDelayLines();
    this.#makeLFO();
    this.#makeConnections();
    this.#lfo.start();
  }

  /**
   * Make various gain stages
   */
  #makeGains() {
    // input and output gains
    this.#in = this.#context.createGain();
    this.#in.gain.value = 1;
    this.#out = this.#context.createGain();
    this.#out.gain.value = 1;
    // depth controls
    this.#leftGain = this.#context.createGain();
    this.#leftGain.gain.value = RolandChorus.DEFAULT_CHORUS_DEPTH;
    this.#rightGain = this.#context.createGain();
    this.#rightGain.gain.value = -RolandChorus.DEFAULT_CHORUS_DEPTH;
    // left and right mixers
    this.#leftMix = this.#context.createGain();
    this.#leftMix.gain.value = 0.5;
    this.#rightMix = this.#context.createGain();
    this.#rightMix.gain.value = 0.5;
  }

  /**
   * Make the LFO that controls the delay time
   */
  #makeLFO() {
    this.#lfo = this.#context.createOscillator();
    this.#lfo.type = "triangle";
    this.#lfo.frequency.value = RolandChorus.DEFAULT_CHORUS_RATE;
  }

  /**
   * Make left and right delay lines
   */
  #makeDelayLines() {
    // left delay line
    this.#leftDelay = this.#context.createDelay();
    this.#leftDelay.delayTime.value = RolandChorus.DEFAULT_DELAY_TIME;
    this.#leftPan = this.#context.createStereoPanner();
    this.#leftPan.pan.value = -RolandChorus.DEFAULT_STEREO_SPREAD; // pan left
    // right delay line
    this.#rightDelay = this.#context.createDelay();
    this.#rightDelay.delayTime.value = RolandChorus.DEFAULT_DELAY_TIME;
    this.#rightPan = this.#context.createStereoPanner();
    this.#rightPan.pan.value = RolandChorus.DEFAULT_STEREO_SPREAD; // pan right
  }

  /**
   * Wire everything together
   */
  #makeConnections() {
    // connect left delay line
    this.#in.connect(this.#leftDelay);
    this.#leftDelay.connect(this.#leftMix);
    this.#in.connect(this.#leftMix);
    this.#leftMix.connect(this.#leftPan);
    this.#leftPan.connect(this.#out);
    // connect right delay line
    this.#in.connect(this.#rightDelay);
    this.#rightDelay.connect(this.#rightMix);
    this.#in.connect(this.#rightMix);
    this.#rightMix.connect(this.#rightPan);
    this.#rightPan.connect(this.#out);
    // connect gains on LFO to control depth
    this.#lfo.connect(this.#leftGain);
    this.#lfo.connect(this.#rightGain);
    this.#leftGain.connect(this.#leftDelay.delayTime);
    this.#rightGain.connect(this.#rightDelay.delayTime);
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
   * Getter for the input gain node.
   * @returns {GainNode} The input gain node.
   */
  get in() {
    return this.#in;
  }

  /**
   * Getter for the output gain node.
   * @returns {GainNode} The output gain node.
   */
  get out() {
    return this.#out;
  }

  /**
   * Sets the depth of the chorus effect. Depth controls the intensity of the modulation.
   * @param {number} d - The depth value, typically between 0 and 1.
   */
  set depth(d) {
    this.#leftGain.gain.value = d / 1000; // normal phase on left ear
    this.#rightGain.gain.value = -d / 1000; // phase invert on right ear
  }

  /**
   * Sets the stereo spread of the chorus effect. Spread controls the stereo separation of the effect.
   * @param {number} s - The spread value, typically between 0 (mono) and 1 (full stereo).
   */
  set spread(s) {
    this.#leftPan.pan.value = -s;
    this.#rightPan.pan.value = s;
  }

  /**
   * Sets the rate of the chorus effect. Rate controls the speed of the modulation.
   * @param {number} r - The rate value in Hz, between 0.01 and 15.
   */
  set rate(r) {
    this.#lfo.frequency.value = Utility.clamp(r, 0.01, 15);
  }

  /**
   * Stops the chorus effect and cleans up resources.
   */
  stop() {
    this.#lfo.stop();
    this.#in.disconnect();
    this.#in = null;
    this.#out.disconnect();
    this.#in = null;
    this.#leftDelay.disconnect();
    this.#leftDelay = null;
    this.#rightDelay.disconnect();
    this.#rightDelay = null;
    this.#leftPan.disconnect();
    this.#leftPan = null;
    this.#rightPan.disconnect();
    this.#rightPan = null;
    this.#leftGain.disconnect();
    this.#leftGain = null;
    this.#rightGain.disconnect();
    this.#rightGain = null;
    this.#leftMix.disconnect();
    this.#leftMix = null;
    this.#rightMix.disconnect();
    this.#rightMix = null;
    this.#monitor.release("chorus");
  }
}

// ----------------------------------------------------------------
// StereoDelay
// stereo delay with feedback
// you can set different delay times for the left and right channels
// ----------------------------------------------------------------

export class StereoDelay {
  static LOWEST_AMPLITUDE = 0.05; // used to work out when the effect fades out
  static DEFAULT_SPREAD = 0.95;
  static DEFAULT_LEFT_DELAY = 0.25;
  static DEFAULT_RIGHT_DELAY = 0.5;
  static DEFAULT_FEEDBACK = 0.4;

  #monitor;
  #in;
  #out;
  #leftDelay;
  #rightDelay;
  #leftPan;
  #rightPan;
  #leftFeedbackGain;
  #rightFeedbackGain;
  #feedback;
  #context;

  /**
   * Creates an instance of StereoDelay.
   * @param {AudioContext} ctx - The audio context for the delay effect.
   * @param {Object} monitor - The monitor object to track the delay effect.
   */
  constructor(ctx, monitor) {
    if (VERBOSE) console.log("Making a Delay");
    this.#context = ctx;
    this.#monitor = monitor;
    this.#monitor.retain("delay");
    this.#makeGains();
    this.#makeDelayLines();
    this.#makeFeedbackPath();
    this.#makeConnections();
  }

  /**
   * Make the input and output gains
   */
  #makeGains() {
    this.#in = this.#context.createGain();
    this.#in.gain.value = 1;
    this.#out = this.#context.createGain();
    this.#out.gain.value = 1;
  }

  /**
   * Make the delay lines for left and right channels
   */
  #makeDelayLines() {
    // left delay
    this.#leftDelay = this.#context.createDelay();
    this.#leftDelay.delayTime.value = StereoDelay.DEFAULT_LEFT_DELAY;
    // pan it to the left
    this.#leftPan = this.#context.createStereoPanner();
    this.#leftPan.pan.value = -StereoDelay.DEFAULT_SPREAD; // pan left (-ve)
    // right delay
    this.#rightDelay = this.#context.createDelay();
    this.#rightDelay.delayTime.value = StereoDelay.DEFAULT_RIGHT_DELAY;
    // pan it to the right
    this.#rightPan = this.#context.createStereoPanner();
    this.#rightPan.pan.value = StereoDelay.DEFAULT_SPREAD; // pan right (+ve)
  }

  /**
   * Make the feedback pathway
   */
  #makeFeedbackPath() {
    this.#feedback = StereoDelay.DEFAULT_FEEDBACK;
    this.#leftFeedbackGain = this.#context.createGain();
    this.#leftFeedbackGain.gain.value = this.#feedback;
    this.#rightFeedbackGain = this.#context.createGain();
    this.#rightFeedbackGain.gain.value = this.#feedback;
  }

  /**
   * Wire everything up
   */
  #makeConnections() {
    // connect up left side
    this.#in.connect(this.#leftDelay);
    this.#leftDelay.connect(this.#leftFeedbackGain);
    this.#leftDelay.connect(this.#leftPan);
    this.#leftPan.connect(this.#out);
    this.#leftFeedbackGain.connect(this.#leftDelay);
    // connect up right side
    this.#in.connect(this.#rightDelay);
    this.#rightDelay.connect(this.#rightFeedbackGain);
    this.#rightDelay.connect(this.#rightPan);
    this.#rightPan.connect(this.#out);
    this.#rightFeedbackGain.connect(this.#rightDelay);
  }

  /**
   * Sets the stereo spread of the delay effect.
   * @param {number} s - The spread value, controlling the stereo separation.
   */
  set spread(s) {
    this.#leftPan.pan.value = -s;
    this.#rightPan.pan.value = s;
  }

  /**
   * Sets the delay time for the left channel.
   * @param {number} d - The delay time in seconds for the left channel.
   */
  set leftDelay(d) {
    this.#leftDelay.delayTime.value = d;
  }

  /**
   * Sets the delay time for the right channel.
   * @param {number} d - The delay time in seconds for the right channel.
   */
  set rightDelay(d) {
    this.#rightDelay.delayTime.value = d;
  }

  /**
   * Sets the feedback amount for the delay effect.
   * @param {number} f - The feedback level, typically between 0 and 1.
   */
  set feedback(f) {
    this.#feedback = f;
    this.#leftFeedbackGain.gain.value = this.#feedback;
    this.#rightFeedbackGain.gain.value = this.#feedback;
  }

  /**
   * Calculates the time it takes for the delay effect to fade out.
   * @returns {number} The estimated fade out time in seconds.
   */
  timeToFadeOut() {
    // work out how long the delay line will take to fade out (exponential decay)
    const m = Math.max(
      this.#leftDelay.delayTime.value,
      this.#rightDelay.delayTime.value
    );
    const n = Math.log(StereoDelay.LOWEST_AMPLITUDE) / Math.log(this.#feedback);
    return m * n;
  }

  /**
   * Getter for the input gain node.
   * @returns {GainNode} The input gain node.
   */
  get in() {
    return this.#in;
  }

  /**
   * Getter for the output gain node.
   * @returns {GainNode} The output gain node.
   */
  get out() {
    return this.#out;
  }

  /**
   * Stops the delay and cleans up.
   */
  stop() {
    this.#in.disconnect();
    this.#in = null;
    this.#out.disconnect();
    this.#out = null;
    this.#monitor.release("delay");
    this.#leftDelay.disconnect();
    this.#leftDelay = null;
    this.#rightDelay.disconnect();
    this.#rightDelay = null;
    this.#leftPan.disconnect();
    this.#leftPan = null;
    this.#rightPan.disconnect();
    this.#rightPan = null;
    this.#leftFeedbackGain.disconnect();
    this.#leftFeedbackGain = null;
    this.#rightFeedbackGain.disconnect();
    this.#rightFeedbackGain = null;
  }
}

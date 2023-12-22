import { VERBOSE } from "./constants";
import { BleepEffect } from "./effects";
import Monitor from "./monitor";

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
    super(ctx, monitor);
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
  setSpread(s, when) {
    this._leftPan.pan.setValueAtTime(-s, when);
    this._rightPan.pan.setValueAtTime(s, when);
  }

  /**
   * Sets the delay time for the left channel.
   * @param {number} d - The delay time in seconds for the left channel.
   * @param {number} when - the time at which the change should occur
   */
  setLeftDelay(d, when) {
    this._leftDelay.delayTime.setValueAtTime(d, when);
  }

  /**
   * Sets the delay time for the right channel.
   * @param {number} d - The delay time in seconds for the right channel.
   * @param {number} when - the time at which the change should occur
   */
  setRightDelay(d, when) {
    this._rightDelay.delayTime.setValueAtTime(d, when);
  }

  /**
   * Sets the feedback amount for the delay effect.
   * @param {number} f - The feedback level, typically between 0 and 1.
   * @param {number} when - the time at which the change should occur
   */
  setFeedback(f, when) {
    // a subtle issue here - we could potentially change the feedback to a smaller value
    // at a future time, which would lead to the echoes being clipped
    // so keep track of the longest feedback we have ever set and use that for the decay calc
    if (f > this._maxFeedback) {
      this._maxFeedback = f;
    }
    this._leftFeedbackGain.gain.setValueAtTime(f, when);
    this._rightFeedbackGain.gain.setValueAtTime(f, when);
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

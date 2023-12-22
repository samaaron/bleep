import Monitor from "./monitor";
import { DEBUG_EFFECTS } from "./flags";

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

export class BleepEffect {

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
    if (DEBUG_EFFECTS) {
      console.log(`starting an effect: ${this.constructor.name}`);
    }
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
    if (DEBUG_EFFECTS) {
      console.log(`stopping an effect: ${this.constructor.name}`);
    }
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




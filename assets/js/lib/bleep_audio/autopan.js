import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Autopanning
 */
export class AutoPan extends BleepEffect {

    static DEFAULT_RATE_HZ = 0.5
    static DEFAULT_SPREAD = 0.8

    _lfo
    _pan
    _gain

    /**
     * Make an autopanning effect
     * @param {AudioContext} ctx - the audio context
     * @param {Monitor} monitor - the monitor to track this object
     */
    constructor(ctx, monitor) {
        super(ctx, monitor);
        this._lfo = new OscillatorNode(ctx, {
            type: "triangle",
            frequency: AutoPan.DEFAULT_RATE_HZ
        });
        this._pan = new StereoPannerNode(ctx);
        this._gain = new GainNode(ctx, {
            gain: AutoPan.DEFAULT_SPREAD
        });
        // connect up
        this._lfo.connect(this._gain);
        this._gain.connect(this._pan.pan);
        this._wetGain.connect(this._pan);
        this._pan.connect(this._out);
        this._lfo.start();
    }

    /**
     * Set the autopanning rate
     * @param {number} r - rate in Hz
     * @param {number} when - the time at which the change should occur
     */
    setRate(r, when) {
        r = Utility.clamp(r, 0, 100);
        this._lfo.frequency.setValueAtTime(r, when);
    }

    /**
     * Set the stereo spread of the autopanner
     * @param {number} s - stereo spread in range [0,1]
     * @param {number} when - the time at which the change should occur
     */
    setSpread(s, when) {
        s = Utility.clamp(s, 0, 1);
        this._gain.gain.setValueAtTime(s, when);
    }

    /**
     * Set the parameters of this effect
     * @param {object} params - key value list of parameters
     * @param {number} when - the time at which the change should occur
     */
    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.rate !== "undefined") {
            this.setRate(params.rate, when);
        }
        if (typeof params.spread !== "undefined") {
            this.setSpread(params.spread, when);
        }
    }

    /**
     * Stop the effect and tidy up
     */
    stop() {
        super.stop();
        this._lfo.stop();
        this._lfo.disconnect();
        this._lfo = null;
        this._pan.disconnect();
        this._pan = null;
        this._gain.disconnect();
        this._gain = null;
    }

}
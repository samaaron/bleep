import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Compressor
 */
export class Compressor extends BleepEffect {

    static DEFAULT_THRESHOLD = -9.7;    // dB
    static DEFAULT_KNEE = 6;            // dB
    static DEFAULT_RATIO = 1.15;        // dB
    static DEFAULT_ATTACK = 0.22/1000;  // 0.22 ms
    static DEFAULT_RELEASE = 100/1000;  // 100 ms

    _compressor

    constructor(ctx, monitor) {
        super(ctx, monitor);

        this._compressor = new DynamicsCompressorNode(ctx, {
            threshold: Compressor.DEFAULT_THRESHOLD,
            knee: Compressor.DEFAULT_KNEE,
            ratio: Compressor.DEFAULT_RATIO,
            attack: Compressor.DEFAULT_ATTACK,
            release: Compressor.DEFAULT_RELEASE
        });
        this._wetGain.connect(this._compressor);
        this._compressor.connect(this._out);
        // we want this fully wet by default
        this.setWetLevel(1, ctx.currentTime);
        this.setDryLevel(0, ctx.currentTime);
    }

   /**
    * Decibel value above which compression starts
    * @param {*} t
    * @param {*} when
    */
    setThreshold(t, when) {
        t = Utility.clamp(t,-100,0);
        this._compressor.threshold.setValueAtTime(t, when);
    }

    /**
     * Sets the sound level in dB at which the compressive curve kicks in
     * @param {*} k
     * @param {*} when
     */
    setKnee(k, when) {
        k = Utility.clamp(k,0,40);
        this._compressor.knee.setValueAtTime(k, when);
    }

    /**
     * The amound of change in dB needed in the input for a 1 dB change in the output
     * @param {*} r
     * @param {*} when
     */
    setRatio(r, when) {
        r = Utility.clamp(r,1,20);
        this._compressor.ratio.setValueAtTime(r, when);
    }

    /**
     * Sets amount of time to reduce the gain by 10dB (in seconds)
     * @param {*} a
     * @param {*} when
     */
    setAttack(a, when) {
        a = Utility.clamp(a,0,1);
        this._compressor.attack.setValueAtTime(a, when);
    }

    /**
     * Sets time required to adapt rate back up by 10 dB (in seconds)
     * @param {*} r
     * @param {*} when
     */
    setRelease(r, when) {
        r = Utility.clamp(r,0,1);
        this._compressor.release.setValueAtTime(r, when);
    }

    /**
     * Set the parameters of this effect
     * @param {object} params - key value list of parameters
     * @param {number} when - the time at which the change should occur
     */
    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.threshold !== "undefined") {
            this.setThreshold(params.threshold, when);
        }
        if (typeof params.knee !== "undefined") {
            this.setKnee(params.knee, when);
        }
        if (typeof params.ratio !== "undefined") {
            this.setRatio(params.ratio, when);
        }
        if (typeof params.attack !== "undefined") {
            this.setAttack(params.attack, when);
        }
        if (typeof params.release !== "undefined") {
            this.setRelease(params.release, when);
        }
    }

    /**
     * Stop the effect and tidy up
     */
    stop() {
        super.stop();
        this._compressor.disconnect();
        this._compressor = null;
    }

}


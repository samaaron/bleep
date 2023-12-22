import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

export class Flanger extends BleepEffect {

    static DEFAULT_DEPTH_MS = 2.3
    static DEFAULT_DELAY_MS = 2.5
    static DEFAULT_FEEDBACK = 0.9
    static DEFAULT_RATE_HZ = 0.3
    static SHAPER_COMPRESSION = 2
    static SHAPER_SIZE = 1000

    _delay
    _direct
    _delayed
    _lfo
    _mixin
    _mixout
    _feedback
    _modgain
    _saturator

    /**
     * Make a flanger
     * @param {AudioContext} ctx - the audio context
     * @param {Monitor} monitor - the monitor to track this effect
     */
    constructor(ctx, monitor) {
        super(ctx, monitor);
        this._lfo = new OscillatorNode(ctx, {
            type: "sine",
            frequency: Flanger.DEFAULT_RATE_HZ
        });
        this._saturator = new WaveShaperNode(ctx, {
            oversample: "2x",
            curve: this.#makeSaturatingCurve(Flanger.SHAPER_COMPRESSION, Flanger.SHAPER_SIZE)
        });
        this._delay = new DelayNode(ctx);
        this._direct = new GainNode(ctx, {
            gain: 0.5
        });
        this._delayed = new GainNode(ctx, {
            gain: 0.5
        });
        this._mixin = new GainNode(ctx, {
            gain: 1
        });
        this._mixout = new GainNode(ctx, {
            gain: 1
        });
        this._feedback = new GainNode(ctx);
        this._modgain = new GainNode(ctx);
        // intitialise
        const now = ctx.currentTime;
        this.setFeedback(Flanger.DEFAULT_FEEDBACK, now);
        this.setDelay(Flanger.DEFAULT_DELAY_MS, now);
        this.setDepth(Flanger.DEFAULT_DEPTH_MS, now);
        // connect
        this._wetGain.connect(this._mixin);
        this._mixin.connect(this._direct)
        this._mixin.connect(this._delay);
        this._delay.connect(this._delayed);
        this._direct.connect(this._mixout);
        this._delayed.connect(this._mixout);
        this._mixout.connect(this._out);
        this._delayed.connect(this._saturator);
        this._saturator.connect(this._feedback);
        this._feedback.connect(this._mixin);
        this._lfo.connect(this._modgain);
        this._modgain.connect(this._delay.delayTime);
        this._lfo.start();
    }

    #makeSaturatingCurve(k, numSamples) {
        const curve = new Float32Array(numSamples);
        for (let i = 0; i < numSamples; i++) {
            const x = (i * 2) / numSamples - 1;
            curve[i] = (Math.PI + k) * x / (Math.PI + k * Math.abs(x));
        }
        return curve;
    }

    setFeedback(k, when) {
        k = Utility.clamp(k, 0, 1);
        this._feedback.gain.setValueAtTime(-k, when);
    }

    setDepth(d, when) {
        d = Utility.clamp(d, 0, 10) / 1000;
        this._modgain.gain.setValueAtTime(d, when);
    }

    setDelay(d, when) {
        const delayMs = Utility.clamp(d, 0.1, 10) / 1000;
        this._delay.delayTime.setValueAtTime(delayMs, when);
    }

    setRate(r, when) {
        r = Utility.clamp(r, 0.01, 100);
        this._lfo.frequency.setValueAtTime(r, when);
    }

    /**
     * Calculates the time it takes for the chorus effect to fade out.
     * @returns {number} The estimated fade out time.
     */
    timeToFadeOut() {
        // delay line is very short for a flanger, this will cover it
        return 0.05;
    }

    /**
     * set ths parameters for the effect
     * @param {object} params - key value list of parameters
     * @param {number} when - the time at which the change should occur
     */
    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.feedback !== "undefined") {
            this.setFeedback(params.feedback, when);
        }
        if (typeof params.depth !== "undefined") {
            this.setDepth(params.depth, when);
        }
        if (typeof params.delay !== "undefined") {
            this.setDelay(params.delay, when);
        }
        if (typeof params.rate !== "undefined") {
            this.setRate(params.rate, when);
        }
    }

    stop() {
        super.stop();
        this._lfo.stop();
        // TODO CLEAN UP
    }
}


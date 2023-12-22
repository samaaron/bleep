import { VERBOSE } from "./constants";
import { BleepEffect } from "./effects";
import Monitor from "./monitor";

export class Flanger extends BleepEffect {
  
    static DEFAULT_DEPTH = 2/1000
    static DEFAULT_DELAY = 5/1000
    static DEFAULT_FEEDBACK = 0.85
    static DEFAULT_RATE = 0.25
    
    _delay
    _direct
    _delayed
    _lfo
    _mixin
    _mixout
    _feedback
    _modgain

    /**
     * Make a flanger
     * @param {AudioContext} ctx - the audio context
     * @param {Monitor} monitor - the monitor to track this effect
     */
    constructor(ctx, monitor) {
        if (VERBOSE) console.log("Making a Flanger");
        super(ctx, monitor);
        this._lfo = new OscillatorNode(ctx,{
            type: "triangle",
            frequency : Flanger.DEFAULT_RATE
        })
        this._delay = new DelayNode(ctx, {
            delayTime: Flanger.DEFAULT_DELAY
        });
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
        this._feedback = new GainNode(ctx, {
            gain: -Flanger.DEFAULT_FEEDBACK
        });
        this._modgain = new GainNode(ctx, {
            gain: Flanger.DEFAULT_DEPTH
        });
        // connect
        this._wetGain.connect(this._mixin);
        this._mixin.connect(this._direct)
        this._mixin.connect(this._delay);
        this._delay.connect(this._delayed);
        this._direct.connect(this._mixout);
        this._delayed.connect(this._mixout);
        this._mixout.connect(this._out);
        this._mixout.connect(this._feedback);
        this._feedback.connect(this._mixin);
        this._lfo.connect(this._modgain);
        this._modgain.connect(this._delay.delayTime);
        this._lfo.start();
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
    }

    stop() {
        super.stop();
        this._lfo.stop();
        // TODO CLEAN UP
    }
}


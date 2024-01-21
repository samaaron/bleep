import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Distortion and Overdrive are basically the same thing
 * but distortion has a steeper compressive function
 * This is the prototype class for both of them
 */
class DistortionPrototype extends BleepEffect {

    static DEFAULT_PRE_GAIN = 1
    static DEFAULT_POST_GAIN = 1
    static DEFAULT_FREQUENCY = 1500
    static DEFAULT_BANDWIDTH = 100

    _distort
    _pregain
    _postgain
    _bandpass

    constructor(ctx, monitor, steepness) {
        super(ctx, monitor);
        this._distort = new WaveShaperNode(ctx, {
            oversample: "4x",
            curve: distortionCurve(steepness)
        });
        this._pregain = new GainNode(ctx, {
            gain: Distortion.DEFAULT_PRE_GAIN
        });
        this._postgain = new GainNode(ctx, {
            gain: Distortion.DEFAULT_POST_GAIN
        });
        this._bandpass = new BiquadFilterNode(ctx, {
            type : "bandpass",
            frequency: Distortion.DEFAULT_FREQUENCY
        })
        this._wetGain.connect(this._pregain);
        this._pregain.connect(this._bandpass);
        this._bandpass.connect(this._distort)
        this._distort.connect(this._postgain);
        this._postgain.connect(this._out);
        // we want this fully wet by default
        this.setWetLevel(1, ctx.currentTime);
        this.setDryLevel(0, ctx.currentTime);
        this.setBandwidth(Distortion.DEFAULT_BANDWIDTH, ctx.currentTime);
    }

    /**
     * Set the parameters
     * @param {*} params - parameter list
     * @param {*} when - the time at which parameter changes should occur
     */
    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.preGain !== "undefined") {
            this.setPreGain(params.preGain, when);
        }
        if (typeof params.postGain !== "undefined") {
            this.setPostGain(params.postGain, when);
        }
        if (typeof params.frequency !== "undefined") {
            this.setFrequency(params.frequency, when);
        }
        if (typeof params.bandwidth !== "undefined") {
            this.setBandwidth(params.bandwidth, when);
        }
    }

    /**
     * The pre-gain control the level going into the distortion curve
     * Higher levels cause more clipping
     * @param {*} g - the gain level
     * @param {*} when - the time at which the change should occur
     */
    setPreGain(g, when) {
        this._pregain.gain.setValueAtTime(g, when);
    }

    /**
 * The post-gain is a level adjustment after the distortion curve
 * Often needed because compression makes the signal louder
 * @param {*} g - the gain level
 * @param {*} when - the time at which the change should occur
 */
    setPostGain(g, when) {
        this._postgain.gain.setValueAtTime(g, when);
    }

    /**
     * The centre frequency of a bandpass filter, which shapes the tone of the distortion
     * @param {*} f - frequency in Hz
     * @param {*} when - the time at which the change should occur
     */
    setFrequency(f, when) {
        this._bandpass.frequency.setValueAtTime(f, when);
    }

    /**
     * The bandwidth (in arbitrary units) of the bandpass filter
     * High values of b give wider bandwidth, in fact b is related to filter Q
     * @param {*} b - bandwidth of the filter in the range 0.1 to 100
     * @param {*} when - the time at which the change should occur
     */
    setBandwidth(b, when) {
        b = Utility.clamp(b, 0.1, 100);
        const q = 1 / b;
        this._bandpass.Q.setValueAtTime(q, when);
    }

    /**
     * Stop this effect and tidy up
     */
    stop() {
        super.stop();
        this._distort.disconnect();
        this._distort = null;
        this._pregain.disconnect();
        this._pregain = null;
        this._postgain.disconnect();
        this._postgain = null;
        this._bandpass.disconnect();
        this._bandpass = null;
    }

}

/**
 * Makes a compressive curve
 * this is a sigmoid function which is linear for k=0 and goes through (-1,-1), (0,0) and (1,1)
* https://stackoverflow.com/questions/22312841/waveshaper-node-in-webaudio-how-to-emulate-distortion
 * @param {*} k - controls the steepness of the distortion curve
 * @returns a float array containing the compressive curve
 */
function distortionCurve(k) {
    const numSamples = 2048;
    const curve = new Float32Array(numSamples);
    for (let i = 0; i < numSamples; i++) {
        const x = (i * 2) / numSamples - 1;
        curve[i] = ((Math.PI + k) * x) / (Math.PI + k * Math.abs(x));
    }
    return curve;
}

/**
 * Distortion
 */
export class Distortion extends DistortionPrototype {

    constructor(ctx, monitor) {
        super(ctx, monitor, 100);
        this.setParams({
            frequency: 1000,
            bandwidth: 75,
            preGain: 0.5,
            postGain: 0.5
        }, ctx.currentTime);
    }
}

/**
 * Overdrive
 */
export class Overdrive extends DistortionPrototype {

    constructor(ctx, monitor) {
        super(ctx, monitor, 10);
        this.setParams({
            frequency: 1200,
            bandwidth: 400,
            preGain: 0.5,
            postGain: 0.5
        }, ctx.currentTime);
    }

}
import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Distortion
 */
export class Distortion extends BleepEffect {

    static DEFAULT_PRE_GAIN = 1
    static DEFAULT_POST_GAIN = 1
    static DEFAULT_FREQUENCY = 1200
    static DEFAULT_BANDWIDTH = 50

    _distort
    _pregain
    _postgain
    _bandpass

    constructor(ctx, monitor) {
        super(ctx, monitor);
        this._distort = new WaveShaperNode(ctx, {
            oversample: "4x",
            curve: distortionCurve(100)
        });
        this._pregain = new GainNode(ctx, {
            gain: Distortion.DEFAULT_PRE_GAIN
        });
        this._postgain = new GainNode(ctx, {
            gain: Distortion.DEFAULT_POST_GAIN
        });
        this._bandpass = new BiquadFilterNode(ctx, {
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

    setPreGain(g, when) {
        this._pregain.gain.setValueAtTime(g, when);
    }

    setPostGain(g, when) {
        this._postgain.gain.setValueAtTime(g, when);
    }

    setFrequency(f, when) {
        this._bandpass.frequency.setValueAtTime(f, when);
    }

    setBandwidth(b, when) {
        b = Utility.clamp(b, 0.1, 100);
        const q = 1 / b;
        this._bandpass.Q.setValueAtTime(q, when);
    }

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

// this is a sigmoid function which is linear for k=0 and goes through (-1,-1), (0,0) and (1,1)
// https://stackoverflow.com/questions/22312841/waveshaper-node-in-webaudio-how-to-emulate-distortion

function distortionCurve(k) {
    const numSamples = 2048;
    const curve = new Float32Array(numSamples);
    for (let i = 0; i < numSamples; i++) {
        const x = (i * 2) / numSamples - 1;
        curve[i] = ((Math.PI + k) * x) / (Math.PI + k * Math.abs(x));
    }
    return curve;
}

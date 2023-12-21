import { VERBOSE } from "./constants";
import { BleepEffect } from "./effects";

/**
 * Prototype structure for phaser and flanger
 * This is abstract - not exported
 */
class PhaserFlangerPrototype extends BleepEffect {

    _leftChannel
    _rightChannel
    _leftPan
    _rightPan

    constructor(ctx, monitor, phase, depth, rate, spread, feedback, highCutoff, leftFreq, rightFreq, leftQ, rightQ) {
        super(ctx, monitor);
        this._leftPan = new StereoPannerNode(ctx, {
            pan: -spread
        });
        this._rightPan = new StereoPannerNode(ctx, {
            pan: spread
        });
        // left channel
        this._leftChannel = new PhaserChannel(ctx, rate*(1-phase), depth, feedback, highCutoff, leftFreq, leftQ);
        this._wetGain.connect(this._leftChannel.in);
        this._leftChannel.out.connect(this._leftPan);
        this._leftPan.connect(this._out);
        // right channel
        this._rightChannel = new PhaserChannel(ctx, rate*(1+phase), depth, feedback, highCutoff, rightFreq, rightQ);
        this._wetGain.connect(this._rightChannel.in);
        this._rightChannel.out.connect(this._rightPan);
        this._rightPan.connect(this._out);
    }

    setParams(params, when) {
        super.setParams(params, when);
        // TODO COMPLETE THIS
    }

    setSpread(s, when) {
        this._leftPan.pan.setValueAtTime(-s, when);
        this._rightPan.pan.setValueAtTime(s, when);
    }

    setFeedback(k, when) {
        this._leftChannel.setFeedback(k, when);
        this._rightChannel.setFeedback(k, when);
    }

    setDepth(d, when) {
        this._leftChannel.setDepth(d, when);
        this._rightChannel.setDepth(d, when);
    }
    setRate(r, when) {
        this._leftChannel.setRate(r*(1-this._RATE_TWEAK), when);
        this._rightChannel.setRate(r*(1+this._RATE_TWEAK), when);
    }

    stop() {
        super.stop();
        this._leftChannel.stop();
        this._leftChannel.out.disconnect();
        this._leftChannel = null;
        this._rightChannel.stop();
        this._rightChannel.out.disconnect;
        this._rightChannel = null;
        this._leftPan.disconnect();
        this._leftPan = null;
        this._rightPan.disconnect();
        this._rightPan = null;
    }

}

// single phaser channel

class PhaserChannel {

    _context
    _freqList
    _qList
    _numStages
    _lfo
    _feedback
    _notch
    _lfogain
    _wetGain
    _dryGain
    _in
    _out
    _highpass

    constructor(ctx, rate, depth, feedback, highCutoff, freqList, qList) {
        this._context = ctx;
        this._freqList = freqList;
        this._qList = qList;
        this._numStages = this._freqList.length;
        // highpass
        this._highpass = new BiquadFilterNode(ctx, {
            type: "highpass",
            frequency: highCutoff,
            Q : 1
        });
        // lfo
        this._lfo = new OscillatorNode(ctx, {
            type: "sine",
            frequency: rate
        });
        // feedback
        this._feedback = new GainNode(ctx, {
            gain: feedback
        });
        // wet and dry paths
        this._wetGain = new GainNode(ctx, {
            gain: 0.5
        });
        this._dryGain = new GainNode(ctx, {
            gain: 0.5
        });
        this._in = new GainNode(ctx, {
            gain: 1
        });
        this._out = new GainNode(ctx, {
            gain: 1
        });
        // filters and gains
        this._notch = [];
        this._lfogain = [];
        for (let i = 0; i < this._numStages; i++) {
            const n = new BiquadFilterNode(ctx, {
                frequency: this._freqList[i],
                Q: this._qList[i],
                type: "allpass"
            });
            this._notch.push(n);
            // lfo gains
            const g = new GainNode(ctx, {
                gain: this._freqList[i] * depth
            });
            this._lfogain.push(g);
        }
        // connect allpass filters
        for (let i = 0; i < this._numStages - 1; i++) {
            this._notch[i].connect(this._notch[i + 1]);
        }
        // connect LFOs
        for (let i = 0; i < this._numStages; i++) {
            this._lfo.connect(this._lfogain[i]);
            this._lfogain[i].connect(this._notch[i].frequency);
        }
        // feedback loop
        this._notch[this._numStages - 1].connect(this._feedback);
        this._feedback.connect(this._notch[0]);
        // dry path
        this._in.connect(this._dryGain);
        this._dryGain.connect(this._out);
        // wet path
        this._in.connect(this._highpass);
        this._highpass.connect(this._notch[0]);
        this._notch[this._numStages - 1].connect(this._wetGain);
        this._wetGain.connect(this._out);
        // start
        this._lfo.start();
    }

    setRate(r, when) {
        this._lfo.frequency.setValueAtTime(r, when);
    }

    setResonance(q, when) {
        for (let i = 0; i < this._numStages; i++) {
            this._notch[i].Q.setValueAtTime(q, when);
        }
    }

    setDepth(d, when) {
        for (let i = 0; i < this._numStages; i++) {
            this._lfogain.gain.setValueAtTime(this._freqList[i] * d, when);
        }
    }

    setFeedback(k, when) {
        this._feedback.gain.setValueAtTime(k, when);
    }

    stop() {
        this._lfo.stop();
        // TODO CLEAN UP
    }

    get in() {
        return this._in;
    }

    get out() {
        return this._out;
    }

}

// THESE GET EXPORTED

export class SimplePhaser extends PhaserFlangerPrototype {
    constructor(ctx, monitor) {
        super(ctx, monitor, 0.05, 0.8, 0.3, 0.99, 0.4, 260, [613,3733], [620,3730], [0.8,0.9], [ 0.8,0.9]);
    }
}

/*
SMALL STONE LOW
export class SimplePhaser extends PhaserFlangerPrototype {
    constructor(ctx, monitor) {
        super(ctx, monitor, 0.05, 0.75, 0.3, 0.99, 0.4, 220, [420,2530], [423,2538], [0.9,0.9], [ 0.9, 0.9]);
    }
}
*/
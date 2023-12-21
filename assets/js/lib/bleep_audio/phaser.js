import { VERBOSE } from "./constants";
import { BleepEffect } from "./effects";

/**
 * Prototype structure for phaser and flanger
 * This is abstract - not exported
 */
class PhaserPrototype extends BleepEffect {

    _leftChannel
    _rightChannel
    _leftPan
    _rightPan
    _phase

    constructor(ctx, monitor, config) {
        super(ctx, monitor);
        this._phase = config.phase;
        this._leftPan = new StereoPannerNode(ctx, {
            pan: -config.spread
        });
        this._rightPan = new StereoPannerNode(ctx, {
            pan: config.spread
        });
        // left channel
        this._leftChannel = new PhaserChannel(ctx, {
            rate: config.rate * (1 - config.phase),
            depth: config.depth,
            feedback: config.feedback,
            lfoType: config.lfoType,
            highCutoff: config.highCutoff,
            freqList: config.leftFreq,
            qList: config.leftQ
        });
        this._wetGain.connect(this._leftChannel.in);
        this._leftChannel.out.connect(this._leftPan);
        this._leftPan.connect(this._out);
        // right channel
        this._rightChannel = new PhaserChannel(ctx, {
            rate: config.rate * (1 + config.phase),
            depth: config.depth,
            feedback: config.feedback,
            lfoType: config.lfoType,
            highCutoff: config.highCutoff,
            freqList: config.rightFreq,
            qList: config.rightQ
        });
        this._wetGain.connect(this._rightChannel.in);
        this._rightChannel.out.connect(this._rightPan);
        this._rightPan.connect(this._out);
    }

    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.spread !== "undefined") {
            this.setSpread(params.spread, when);
        }
        if (typeof params.feedback !== "undefined") {
            this.setFeedback(params.feedback, when);
        }
        if (typeof params.depth !== "undefined") {
            this.setDepth(params.depth, when);
        }
        if (typeof params.rate !== "undefined") {
            this.setRate(params.rate, when);
        }
        if (typeof params.resonance !== "undefined") {
            this.setResonance(params.resonance, when);
        }
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
        this._leftChannel.setRate(r * (1 - this._phase), when);
        this._rightChannel.setRate(r * (1 + this._phase), when);
    }

    setResonance(q, when) {
        this._leftChannel.setResonance(q, when);
        this._rightChannel.setResonance(q, when);
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

    constructor(ctx, config) {
        this._context = ctx;
        this._freqList = config.freqList;
        this._qList = config.qList;
        this._numStages = this._freqList.length;
        // highpass
        this._highpass = new BiquadFilterNode(ctx, {
            type: "highpass",
            frequency: config.highCutoff,
            Q: 1
        });
        // lfo
        this._lfo = new OscillatorNode(ctx, {
            type: config.lfoType,
            frequency: config.rate
        });
        // feedback
        this._feedback = new GainNode(ctx, {
            gain: config.feedback
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
                gain: this._freqList[i] * config.depth
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
        this._feedback.connect(this._highpass);
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
            this._lfogain[i].gain.setValueAtTime(this._freqList[i] * d, when);
        }
    }

    setFeedback(k, when) {
        this._feedback.gain.setValueAtTime(k, when);
    }

    stop() {
        this._lfo.stop();
        for (let i = 0; i < this._numStages; i++) {
            this._notch[i].disconnect();
            this._notch[i] = null;
            this._lfogain[i].disconnect();
            this._lfogain[i] = null;
        }
        this._freqList = null;
        this._qList = null;
        this._lfo.disconnect();
        this._lfo = null;
        this._wetGain.disconnect();
        this._wetGain = null;
        this._dryGain.disconnect();
        this._dryGain = null;
        this._in.disconnect();
        this._in = null;
        this._out.disconnect();
        this._out = null;
        this._highpass.disconnect();
        this._highpass = null;
    }

    get in() {
        return this._in;
    }

    get out() {
        return this._out;
    }

}

export class DeepPhaser extends PhaserPrototype {
    constructor(ctx, monitor) {
        super(ctx, monitor, {
            phase: 0.02,
            depth: 0.8,
            rate: 0.3,
            spread: 0.99,
            feedback: 0.4,
            highCutoff: 120,
            lfoType: "triangle",
            leftFreq: [625, 600, 1200, 1250, 3200, 3210],
            rightFreq: [615, 620, 1210, 1220, 3215, 3205],
            leftQ: [0.4, 0.4, 0.5, 0.5, 0.6, 0.6],
            rightQ: [0.4, 0.4, 0.5, 0.5, 0.6, 0.6]
        });
    }
}

export class ThickPhaser extends PhaserPrototype {
    constructor(ctx, monitor) {
        super(ctx, monitor, {
            phase: 0.05,
            depth: 0.8,
            rate: 0.3,
            spread: 0.99,
            feedback: 0.4,
            highCutoff: 220,
            lfoType: "triangle",
            leftFreq: [625, 3200],
            rightFreq: [615, 3200],
            leftQ: [0.43, 0.75],
            rightQ: [0.45, 0.74]
        });
    }
}

export class PicoPebble extends PhaserPrototype {
    constructor(ctx, monitor) {
        super(ctx, monitor, {
            phase: 0.01,
            depth: 0.93,
            rate: 0.2,
            spread: 0.99,
            feedback: 0.2,
            highCutoff: 264,
            lfoType: "triangle",
            leftFreq: [3215],
            rightFreq: [3225],
            leftQ: [0.75],
            rightQ: [0.75]
        });
    }
}


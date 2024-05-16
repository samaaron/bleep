import Constants from "../js/Constants.js";
import Monitor from "../js/Monitor.js";
import SamplePlayer from "../js/SamplePlayer.js";
import Utility from "../js/Utility.js";
import Clock from "../js/Clock.js";

class Granulator extends SamplePlayer {

    static MIN_RAMP_SEC = 0.005; // shortest grain onset/offset ramp in sec

    static MAX_GRAIN_AMP = 1.0; // maximum amplitude of a grain

    static STOP_DELAY_SEC = 0.2; // extra time lag before we stop the grain player in sec

    static PARAM_RANGES = {
        amp: { min: 0, max: 1, default: 0.8 },              // overall volume
        attack: { min: 0, max: 5, default: 0.01 },          // attack in beats
        cutoff: { min: 20, max: 20000, default: 20000 },    // filter cutoff in Hz
        density: { min: 1, max: 20, default: 10 },          // grain density in grains per second
        detune: { min: -2400, max: 2400, default: 0 },      // sample detune in cents
        detune_var: { min: 0, max: 2400, default: 0 },      // pitch variance in cents
        dur: { min: 0.02, max: 100, default: 1 },           // duration in beats
        index: { min: 0, max: 1, default: 0.5 },            // buffer index
        index_var: { min: 0, max: 1, default: 0.01 },       // time variance
        pan: { min: -1, max: 1, default: 0 },               // pan
        pan_var: { min: 0, max: 1, default: 0 },            // pan variance
        rate: { min: 0.1, max: 10, default: 1 },            // sample rate multiplier
        release: { min: 0, max: 5, default: 2 },            // release in beats (defaults to 2 to get overlap)
        resonance: { min: 0, max: 25, default: 0 },         // filter resonance
        send: { min: 0, max: 1, default: 0 },               // gain to fx send
        shape: { min: 0, max: 1, default: 0.5 },            // grain shape
        size: { min: 0.1, max: 1, default: 0.2 },           // grain size in sec
        time_var: { min: 0, max: 0.1, default: 0.05 },      // time variance of grain start (jitter)
    };

    /**
     * the audio node that grains are connected to
     * @type {AudioNode}
     */
    _sink = null;

    /**
     * play a note consisting of many grains
     * @param {number} tim 
     * @param {object} opts 
     */
    play(tim, opts) {
        // possibly we are working too quickly and the sample has not loaded in time
        if (!this._buffer) {
            console.error(`Granulator : cannot play at time ${tim}, sample ${this._name} has not loaded`);
            this.releaseAll();
            return;
        }
        // check bounds for opts as we set them
        const params = this.setUserParams(Granulator.PARAM_RANGES, opts);
        // wire in a filter if needed, otherwise grains connect to the volume gain
        if (params && params.cutoff < Granulator.PARAM_RANGES["cutoff"].max) {
            this._sink = this.makeFilterNode(params);
            this._sink.connect(this._volume);
        } else {
            this._sink = this._volume;
        }
        // set the parameters for this note
        const { attack, release, duration, numberOfGrains, bufferLength, stepSize, delta } = this.makeParameters(params);
        // where we start reading grains from in the buffer
        let grainStartSec = params.index * bufferLength;
        // set the send level
        this._send.gain.value = params.send;
        // apply an overall envelope
        this.applyOverallEnvelope(tim, duration, attack, release, params.amp);
        // main loop
        for (let i = 0; i < numberOfGrains; i++) {
            const timeOffset = Math.max(0, i * stepSize + Utility.randomFloat(-params.time_var, params.time_var));
            const grainPlayTime = tim + timeOffset;
            grainStartSec += Utility.clamp(Utility.randomFloat(-delta, delta), 0, bufferLength);
            this.playGrain(grainPlayTime, grainStartSec, params);
        }
        // schedule cleanup after last grain has played (plus extra delay for good luck)
        let stopTime = tim - this._ctx.currentTime + duration + release + params.size + Granulator.STOP_DELAY_SEC;
        setTimeout(() => {
            this.releaseAll();
        }, stopTime * 1000);
    }

    /**
     * make all the parameters for a note of the granulator
     * @param {object} params 
     * @returns {object}
     */
    makeParameters(params) {
        // convert times to bpm 
        const clock = Clock.getInstance();
        // convert beat-based quantities to seconds
        const attack = clock.beatsToSeconds(params.attack);
        const release = clock.beatsToSeconds(params.release);
        const duration = clock.beatsToSeconds(params.dur);
        // number of grains, rounding up so we have at least one
        const numberOfGrains = Math.ceil(params.density * duration);
        // work out the step size, which is how far we step in seconds for each grain
        const stepSize = (duration + release) / numberOfGrains;
        // work out far we step through the buffer on each iteration
        const bufferLength = this._buffer.duration - params.size;
        const delta = params.index_var * this._buffer.duration;
        // return the parameters
        return {
            attack: attack,
            release: release,
            duration: duration,
            numberOfGrains: numberOfGrains,
            bufferLength: bufferLength,
            stepSize: stepSize,
            delta: delta
        }
    }

    /**
     * play a grain
     * @param {number} grainPlayTime 
     * @param {number} grainStartSec 
     * @param {object} params 
     */
    playGrain(grainPlayTime, grainStartSec, params) {
        // make the source node, with random detune
        const randomDetune = params.detune + Utility.randomFloat(-params.detune_var, params.detune_var);
        let source = new AudioBufferSourceNode(this._ctx, {
            playbackRate: params.rate,
            detune: randomDetune,
            buffer: this._buffer
        });
        // make the pan node, with random pan
        const randomPan = Utility.clamp(params.pan + Utility.randomFloat(-params.pan_var, params.pan_var), -1, 1);
        const pan = new StereoPannerNode(this._ctx, {
            pan: randomPan
        });
        // make the gain node
        const gain = new GainNode(this._ctx);
        // register the above with the monitor
        this._monitor.retainGroup([Monitor.PAN, Monitor.AUDIO_SOURCE, Monitor.GAIN], Monitor.GRANULATOR);
        // wire it all up
        source.connect(gain);
        gain.connect(pan);
        pan.connect(this._sink);
        // apply the envelope shape
        this.applyGrainEnvelope(gain, grainPlayTime, params.size, params.shape);
        // tidy up when done
        source.onended = () => {
            source.disconnect();
            gain.disconnect();
            pan.disconnect();
            this._monitor.releaseGroup([Monitor.PAN, Monitor.AUDIO_SOURCE, Monitor.GAIN], Monitor.GRANULATOR);
        };
        // play this grain
        source.start(grainPlayTime, grainStartSec, params.size);
        // debug
        if (Constants.DEBUG_GRANULATOR) {
            console.log(`played grain at time ${grainPlayTime} starting ${grainStartSec} with length ${params.size}`);
        }
    }

    /**
     * apply envelope to a grain
     * varies from ramp down (0) to triangle (0.5) to ramp up (1)
     * @param {GainNode} gain 
     * @param {number} tim 
     * @param {number} grainLength 
     * @param {number} shape 
     */
    applyGrainEnvelope(gain, tim, grainLength, shape) {
        const peakTime = Granulator.MIN_RAMP_SEC + (grainLength - 2 * Granulator.MIN_RAMP_SEC) * shape;
        gain.gain.setValueAtTime(0, tim);
        gain.gain.linearRampToValueAtTime(Granulator.MAX_GRAIN_AMP, tim + peakTime);
        gain.gain.linearRampToValueAtTime(0, tim + grainLength);
    }

    /**
     * apply overall envelope to the volumne of the granulator
     * @param {number} tim 
     * @param {number} duration 
     * @param {number} attack 
     * @param {number} release 
     * @param {number} amp 
     */
    applyOverallEnvelope(tim, duration, attack, release, amp) {
        this._volume.gain.setValueAtTime(0, tim);
        this._volume.gain.linearRampToValueAtTime(amp, tim + attack);
        this._volume.gain.setValueAtTime(amp, tim + duration);
        this._volume.gain.linearRampToValueAtTime(0, tim + duration + release);
    }

}

export default Granulator;
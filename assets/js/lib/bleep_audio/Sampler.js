import Constants from "../js/Constants.js";
import Monitor from "../js/Monitor.js";
import SamplePlayer from "../js/SamplePlayer.js";

class Sampler extends SamplePlayer {

    /**
     * parameter ranges and defaults
     */
    static PARAM_RANGES = {
        amp: { min: 0, max: 1, default: 0.8 },              // volume
        cutoff: { min: 20, max: 20000, default: 20000 },    // filter cutoff
        detune: { min: -2400, max: 2400, default: 0 },      // detune in cents
        dur: { min: 0.02, max: 100, default: 1 },           // duration in beats
        pan: { min: -1, max: 1, default: 0 },               // pan
        rate: { min: 0.1, max: 10, default: 1 },            // sample rate multiplier
        resonance: { min: 0, max: 25, default: 0 },         // filter resonance
        send: { min: 0, max: 1, default: 0 },               // fx send level
    };

    /**
     * @type {number}
     */
    static OFFSET_RAMP_TIME = 0.01 // duration of decay ramp in seconds

    /**
     * @type {StereoPannerNode}
     */
    _pan = null;

    /**
     * @type {AudioBufferSourceNode}
     */
    _source = null;

    /**
     * release the volume and send gain nodes
     */
    releaseAll() {
        super.releaseAll();
        this._monitor.releaseGroup([Monitor.GAIN, Monitor.GAIN], Monitor.SAMPLER);
        // remove source if we made one
        if (this._source !== null) {
            this._source.disconnect();
            this._monitor.release(Monitor.AUDIO_SOURCE, Monitor.SAMPLER);
        }
        // remove pan if we made one
        if (this._pan !== null) {
            this._pan.disconnect();
            this._monitor.release(Monitor.PAN, Monitor.SAMPLER);
        }
    }

    /**
     * Play the sampler
     * @param {float} tim
     * @param {object} opts
     */
    play(tim, opts) {
        // possibly the sample has not loaded in time
        if (!this._buffer) {
            console.error(`Sampler : cannot play at time ${tim}, sample ${this._name} has not loaded`);
            this.releaseAll();
            return;
        }
        // check bounds for opts as we set them
        const params = this.setUserParams(Sampler.PARAM_RANGES, opts);
        // set gain parameters
        this.setGains(tim, opts, params);
        // source node
        this.makeSourceNode(params);
        let lastNode = this._source;
        // possibly add filter node
        if (params && params.cutoff < Sampler.PARAM_RANGES["cutoff"].max) {
            lastNode = this.makeFilterNode(params, lastNode);
        }
        // possibly add pan node
        if (params && params.pan !== 0) {
            lastNode = this.makePanNode(params, lastNode);
        }
        // last connection is to the gain node that controls volume
        lastNode.connect(this._volume);
        // stopping
        this._source.onended = () => {
            this.releaseAll();
        }
        // start
        this._source.start(tim);
        // debug
        this.debug(tim, params);
    }

   /**
    * debug if required
    * @param {number} tim
    * @param {object} params
    */
    debug(tim, params) {
        if (Constants.DEBUG_SAMPLER) {
            console.log(`sampler playing "${this._name}" at time ${tim} with params:`);
            Object.keys(params).forEach(key => {
                console.log(key + ' : ' + params[key]);
            });
        }
    }

    /**
     * set the gains, cutting short if duration is less than sample length
     * @param {number} tim
     * @param {object} params
     */
    setGains(tim, opts, params) {
        // set gain parameters
        this._volume.gain.value = params.amp;
        this._send.gain.value = params.send;
        // silence the sample before the end only if a duration was specified
        if (opts.dur) {
            const clock = Clock.getInstance();
            const duration = clock.beatsToSeconds(params.dur);
            if (duration < this._buffer.duration) {
                this._volume.gain.setValueAtTime(params.amp, tim + duration - Sampler.OFFSET_RAMP_TIME);
                this._volume.gain.linearRampToValueAtTime(0, tim + duration);
            }
        }
    }

    /**
     * make the source node
     * @param {object} params
     */
    makeSourceNode(params) {
        this._source = new AudioBufferSourceNode(this._ctx, {
            playbackRate: params.rate,
            detune: params.detune,
            buffer: this._buffer
        });
        this._monitor.retain(Monitor.AUDIO_SOURCE, Monitor.SAMPLER);
    }

    /**
     * make a panning node
     * @param {object} params
     * @param {AudioNode} lastNode
     * @returns {AudioNode}
     */
    makePanNode(params, lastNode) {
        this._pan = new StereoPannerNode(this._ctx, {
            pan: params.pan
        });
        this._monitor.retain(Monitor.PAN, Monitor.SAMPLER);
        lastNode.connect(this._pan);
        lastNode = this._pan;
        return lastNode;
    }

}

export default Sampler;
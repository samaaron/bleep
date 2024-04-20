import AudioSystem from "../js/AudioSystem.js";
import Monitor from "../js/Monitor.js";
import SampleCache from "../js/SampleCache.js";
import Utility from "../js/Utility.js";

class SamplePlayer {

    /**
     * @type {AudioBuffer}
     */
    _buffer = null;

    /**
     * @type {string}
     */
    _name = null;

    /**
     * @type {GainNode}
     */
    _volume = null;

    /**
     * @type {BiquadFilterNode}
     */
    _filter = null;

    /**
     * @type {Monitor}
     */
    _monitor = Monitor.getInstance();

    /**
     * @type {AudioContext}
     */
    _ctx = AudioSystem.getInstance().context;

    /**
     * constructor
     */
    constructor() {
        this._volume = new GainNode(this._ctx);
        this._volume.connect(this._send);
        this._monitor.retainGroup([Monitor.GAIN, Monitor.GAIN], Monitor.SAMPLE_PLAYER);
    }

    /**
     * Load the audio file for the sampler from the cache (or throw an error)
     * @param {string} filename
     */
    async load(filename) {
        this._name = filename;
        const cache = SampleCache.getInstance();
        if (cache.has(filename)) {
            this._buffer = cache.get(filename);
        } else {
            console.error(`Could not find ${filename} in cache`);
            cache.incrementMissCount();
        }
    }

    /**
     * Get the output node
     * @returns {AudioNode}
     */
    get out() {
        return this._volume;
    }

    /**
     * Get the send node
     * @returns {AudioNode}
     */
    get send() {
        return this._send;
    }

    /**
     * set the user parameters - note that opts has come from fengari and we can't iterate
     * over keys of a proxy, so we iterate over the known parameters
     * @param {object} defaults
     * @param {object} opts
     * @returns {object} checked parameters
     */
    setUserParams(defaults, opts) {
        opts = opts || {};
        let params = {};
        Object.keys(defaults).forEach(key => {
            if (opts[key] !== undefined) {
                params[key] = Utility.clamp(opts[key], defaults[key].min, defaults[key].max);
            } else {
                params[key] = defaults[key].default;
            }
        });
        return params;
    }

    /**
     * clean up the web audio components we used
     */
    releaseAll() {
        // remove gains
        this._volume.disconnect();
        this._send.disconnect();
        this._monitor.releaseGroup([Monitor.GAIN, Monitor.GAIN], Monitor.SAMPLE_PLAYER);
        // remove filter if we made one
        if (this._filter !== null) {
            this._filter.disconnect();
            this._monitor.release(Monitor.BIQUAD, Monitor.SAMPLE_PLAYER);
        }
    }

    /**
     * make a lowpass filter node
     * @param {object} params
     * @param {AudioNode} lastNode
     * @returns {AudioNode}
     */
    makeFilterNode(params, lastNode) {
        this._filter = new BiquadFilterNode(this._ctx, {
            frequency: params.cutoff,
            Q: params.resonance
        });
        this._monitor.retain(Monitor.BIQUAD, Monitor.SAMPLE_PLAYER);
        if (lastNode) {
            lastNode.connect(this._filter);
        }
        lastNode = this._filter;
        return lastNode;
    }

    /**
     * play method (abstract)
     * @param {number} tim
     * @param {object} opts
     */
    play(tim, opts) {
        throw new Error("SamplePlayer : play must be overridden");
    }

}

export default SamplePlayer;
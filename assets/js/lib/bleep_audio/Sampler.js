import Monitor from "./monitor"

// TODO #20 should sampler have a built-in pan or is it an effect?
// TODO #21 should sampler have a built-in filter or is it an effect?

export default class Sampler {

    #source = null;
    #volume = null;
    #monitor = null;
    #lowpass = null;
    #pan = null;

    /**
     * @param {AudioContext} ctx
     * @param {AudioBuffer} buffer
     * @param {object} opts
     */
    constructor(ctx, monitor, buffer, opts) {
        console.log("made a sampler player");
        this.#monitor = monitor;
        // source
        this.#source = new AudioBufferSourceNode(ctx, {
            buffer: buffer,
            playbackRate: opts.rate !== undefined ? opts.rate : 1,
            loop: opts.loop !== undefined ? opts.loop : false
        });
        let lastNode = this.#source;
        // lowpass
        lastNode = this.addLowpassNode(ctx,lastNode,opts.cutoff);
        // pan
        lastNode = this.addPanNode(ctx,lastNode,opts.pan);
        // volume gain
        this.#volume = new GainNode(ctx, {
            gain: opts.level !== undefined ? opts.level : 1
        });
        // connect up
        lastNode.connect(this.#volume);
        // register with monitor
        this.#monitor.retain(Monitor.SOURCE_NODE);
        this.#monitor.retain(Monitor.GAIN_NODE);
        // ensure cleanup
        this.#source.onended = () => {
            this.releaseAll();
        }
    }

    /**
     * add a pan node if the pan value is not zero (center)
     * @param {AudioContext} ctx
     * @param {AudioNode} lastNode
     * @param {number} pan
     * @returns {AudioNode} - The last node in the audio graph
     */
    addPanNode(ctx, lastNode, pan) {
        if (pan !== undefined) {
            console.log("making pan node");
            this.#pan = new StereoPannerNode(ctx, {
                pan: pan
            });
            this.#monitor.retain(Monitor.PAN_NODE);
            lastNode.connect(this.#pan);
            lastNode = this.#pan;
        }
        return lastNode;
    }

    /**
     * add a lowpass filter node if the cutoff value is defined
     * @param {AudioContext} ctx
     * @param {AudioNode} lastNode
     * @param {number} cutoff
     * @returns {AudioNode} - The last node in the audio graph
     */
    addLowpassNode(ctx, lastNode, cutoff) {
        if (cutoff !== undefined) {
            console.log("making lowpass node");
            this.#lowpass = new BiquadFilterNode(ctx, {
                type: "lowpass",
                frequency: cutoff
            });
            this.#monitor.retain(Monitor.LOWPASS_NODE);
            lastNode.connect(this.#lowpass);
            lastNode = this.#lowpass;
        }
        return lastNode;
    }

    /**
     * clean up and remove from monitor
     */
    releaseAll() {
        console.log("releasing sample");
        this.#volume.disconnect();
        this.#source.disconnect();
        this.#monitor.release(Monitor.SOURCE_NODE);
        this.#monitor.release(Monitor.GAIN_NODE);
        if (this.#lowpass!==null) {
            this.#lowpass.disconnect();
            this.#monitor.release(Monitor.LOWPASS_NODE);
        }
        if (this.#pan!==null) {
            this.#pan.disconnect();
            this.#monitor.release(Monitor.PAN_NODE);
        }
    }

    /**
     * @returns {GainNode}
     */
    get out() {
        return this.#volume;
    }

    /**
     * @param {number} time
     */
    play(time) {
        console.log("playing sample");
        this.#source.start(time);
    }

}
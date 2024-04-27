import Monitor from "./monitor"

// TODO #20 should sampler have a built-in pan or is it an effect?
// TODO #21 should sampler have a built-in filter or is it an effect?

export default class Sampler {

    #source = null;
    #volume = null;
    #monitor = null;
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
        // pan
        this.addPanNode(ctx,this.#source,opts.pan);
        // volume gain
        this.#volume = new GainNode(ctx, {
            gain: opts.level !== undefined ? opts.level : 1
        });
        // connect up
        this.#source.connect(this.#volume);
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
     * @returns
     */
    addPanNode(ctx, lastNode, pan) {
        if (pan !== 0) {
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
     * clean up and remove from monitor
     */
    releaseAll() {
        console.log("releasing sample");
        this.#volume.disconnect();
        this.#source.disconnect();
        this.#monitor.release(Monitor.SOURCE_NODE);
        this.#monitor.release(Monitor.GAIN_NODE);
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
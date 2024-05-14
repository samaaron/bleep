export default class GrainPlayer {

    #source
    #opts
    #ctx
    #volume

    /**
     * @param {AudioContext} ctx
     * @param {AudioBuffer} buffer
     * @param {object} opts
     */
    constructor(ctx,buffer,opts) {
        console.log("made a grain player");
        this.#ctx = ctx;
        this.#opts = opts;
        this.#source = new AudioBufferSourceNode(ctx, {
            buffer : buffer
        });
        this.#volume = new GainNode(ctx,{
            gain : 1
        });
        this.#source.connect(this.#volume);
    }

    get out() {
        return this.#volume;
    }

    play(time) {
        console.log("playing grains");
        this.#source.start(time);
    }

}

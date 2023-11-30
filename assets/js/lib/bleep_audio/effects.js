export class Reverb {

    #context
    #monitor
    #in
    #out

    constructor(ctx, monitor) {
        console.log("Making a Reverb");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("reverb");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#in.connect(this.#out);
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    stop() {
        this.#in.disconnect();
        this.#out.disconnect();
        this.#in = null;
        this.#out = null;
        this.#monitor.release("reverb");
    }

}


export class RolandChorus {

    #context
    #monitor
    #in
    #out

    constructor(ctx, monitor) {
        console.log("Making a Chorus");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("chorus");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#in.connect(this.#out);
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    stop() {
        this.#in.disconnect();
        this.#out.disconnect();
        this.#in = null;
        this.#out = null;
        this.#monitor.release("chorus");
    }

}


export class StereoDelay {

    #context
    #monitor
    #in
    #out

    constructor(ctx, monitor) {
        console.log("Making a Delay");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("delay");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#in.connect(this.#out);
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    stop() {
        this.#in.disconnect();
        this.#out.disconnect();
        this.#in = null;
        this.#out = null;
        this.#monitor.release("delay");
    }

}

export class EffectsChain {

    #context
    #monitor
    #in
    #out
    #tail

    constructor(ctx, monitor) {
        console.log("Making an Effects Chain");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("fxchain");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#tail = null;
    }

    addSerial(effect, outLevel) {
        if (this.#tail) {
            this.#tail.disconnect(this.#out);
            this.#tail.connect(effect.in);
        } else {
            this.#in.connect(effect.in);
        }
        effect.out.connect(this.#out);
        this.#tail = effect.out;
    }

    addParallel(effect, outLevel) {
        this.#in.connect(effect.in);
        effect.out.connect(this.#out);
        this.#tail = effect.out;
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    stop() {
        this.#in.disconnect();
        this.#out.disconnect();
        this.#in = null;
        this.#out = null;
        this.#monitor.release("fxchain");
    }

}
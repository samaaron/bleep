// this class wraps inputs and outpus to an effects node, necessary so that we can
// have a number of connection points (with different gains) to the same effect
// and add/remove them as needed without having to create an effect class 
// (Reverb, RolandChorus etc) each time we play a note

class EffectsHolder {

    #in
    #out
    #monitor

    constructor(ctx, effect, monitor) {
        this.#monitor = monitor;
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#in.connect(effect.in);
        effect.out.connect(this.#out);
        this.#monitor.retain("fxholder");
    }

    set inputLevel(v) {
        this.#in.gain.value = v;
    }

    set outputLevel(v) {
        this.#out.gain.value = v;
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    dispose() {
        console.log("called dispose on effects holder");
        this.#in.disconnect();
        this.#out.disconnect();
        this.#in = null;
        this.#out = null;
        this.#monitor.release("fxholder");
    }

}

export class Reverb {

    #context
    #monitor
    #isValid
    #convolver

    constructor(ctx, monitor) {
        console.log("Making a Reverb");
        console.log("CHECK");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#isValid = false;
        // monitor
        this.#monitor.retain("reverb");
        this.#convolver = ctx.createConvolver();
    }

    async load(filename) {
        const impulseResponse = await this.getImpulseResponseFromFile(filename);
        if (this.#isValid) {
          this.#convolver.buffer = impulseResponse;
        }
      }

    async getImpulseResponseFromFile(filename) {
        try {
            let reply = await fetch(`/bleep_audio/impulses/${filename}`);
            this.#isValid = true;
            return this.#context.decodeAudioData(await reply.arrayBuffer());
        } catch (err) {
            this.#isValid = false;
            console.log("unable to load the impulse response file called " + filename);
        }
    }

    get duration() {
        // make this available since we must wait this long before disconnecting anything
        // to avoid reverb tails being cut off
        return this.#convolver.buffer.duration;
    }

    get in() {
        return this.#convolver;
    }

    get out() {
        return this.#convolver;
    }

    stop() {
        this.#convolver.disconnect();
        this.#convolver = null;
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
    #holders
    #disconnectPause 

    constructor(ctx, monitor) {
        console.log("Making an Effects Chain");
        this.#holders = [];
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("fxchain");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#tail = null;
        // this is the maximum time in seconds we must wait before disconnecting an effects chain
        // for reverberation this corresponds to the length in sec of the impulse response
        this.#disconnectPause = 0; 
    }

    addSerial(effect) {
        const holder = new EffectsHolder(this.#context,effect,this.#monitor);
        // store a reference to this holder so we can dispose of it later
        this.#holders.push(holder); 
        console.log("Added a serial effect");
        console.log(this.#holders);
        if (this.#tail) {
            this.#tail.disconnect(this.#out);
            this.#tail.connect(holder.in);
        } else {
            this.#in.connect(holder.in);
        }
        holder.out.connect(this.#out);
        this.#tail = holder.out;
        // update the maximum time to wait before disconnecting
        this.#updateDisconnectPause(effect);
    }

    addParallel(effect) {
        const holder = new EffectsHolder(this.#context,effect,this.#monitor);
        // store a reference to this holder so we can dispose of it later
        this.#holders.push(holder); 
        console.log("Added a parallel effect");
        console.log(this.#holders);
        this.#in.connect(holder.in);
        holder.out.connect(this.#out);
        this.#tail = holder.out;
        // update the maximum time to wait before disconnecting
        this.#updateDisconnectPause(effect);
    }

    #updateDisconnectPause(effect) {
        if (effect.duration != undefined) {
            if (effect.duration > this.#disconnectPause) {
                this.#disconnectPause = effect.duration;
            }
        }
    }

    set inputLevel(v) {
        this.#in.gain.value = v;
    }

    set outputLevel(v) {
        this.#out.gain.value = v;
    }

    get in() {
        return this.#in;
    }

    get out() {
        return this.#out;
    }

    // stop the effects chain, adding a delay to make sure we don't
    // clip any release tails
    // the delay is set by disconnectPause
    stop(when) {
        let stopTime = when - this.#context.currentTime;
        if (stopTime < 0) stopTime = 0;
        setTimeout(() => {
            console.log("stopping and killing the effects chain");
            for (let i = 0; i < this.#holders.length; i++) {
                this.#holders[i].dispose();
                this.#holders[i] = null;
            }
            this.#holders = null;
            this.#in.disconnect();
            this.#out.disconnect();
            this.#in = null;
            this.#out = null;
            this.#monitor.release("fxchain");
        }, (stopTime + this.#disconnectPause) * 1000);
    }

}
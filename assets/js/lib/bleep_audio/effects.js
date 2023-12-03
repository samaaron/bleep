import Utility from "./utility";

const VERBOSE = false;

// ----------------------------------------------------------------
// EffectsHolder - wiring for an effect
// wraps inputs and outpus to an effects node, necessary so that we can
// have a several connection points (with different gains) to the same effect
// and add/remove as needed without having to create an effect object 
// each time we play a note
// ----------------------------------------------------------------

class EffectsHolder {

    #in
    #out
    #monitor
    #wetGain
    #dryGain

    /**
     * Creates an instance of EffectsHolder.
     * @param {AudioContext} ctx - The audio context used for creating audio nodes.
     * @param {Object} effect - The audio effect to be applied.
     * @param {Object} monitor - The monitor object to track the effects holder.
     * @param {number} wetLevel - The amount of wet signal output.
     * @param {number} outputLevel - The output level for the effects holder.
     */
    constructor(ctx, effect, monitor, wetLevel, outputLevel) {
        this.#monitor = monitor;
        // input node
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        // output node
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        // gain for the wet path
        this.#wetGain = ctx.createGain();
        this.#wetGain.gain.value = wetLevel;
        // gain for the dry path
        this.#dryGain = ctx.createGain();
        this.#dryGain.gain.value = 1 - wetLevel;
        // connect the dry path
        this.#in.connect(this.#dryGain);
        this.#dryGain.connect(this.#out);
        // connect the wet path
        this.#in.connect(this.#wetGain);
        this.#wetGain.connect(effect.in);
        effect.out.connect(this.#out);
        // set the output level (usually 1)
        this.#out.gain.value = outputLevel;
        // monitor
        this.#monitor.retain("fxholder");
    }

    /**
     * Sets the amount of wet signal output.
     * @param {number} v - The value to set the wet gain level.
     */
    set wetLevel(v) {
        this.#wetGain.gain.value = v;
        this.#dryGain.gain.value = 1 - v;
    }

    /**
     * Sets the output level of the effect.
     * @param {number} v - The value to set the output gain level.
     */
    set outputLevel(v) {
        this.#out.gain.value = v;
    }

    /**
     * Getter for the input gain node.
     * @returns {GainNode} The input gain node.
     */
    get in() {
        return this.#in;
    }

    /**
     * Getter for the output gain node.
     * @returns {GainNode} The output gain node.
     */
    get out() {
        return this.#out;
    }

    /**
     * Cleans up resources used by this EffectsHolder.
     */
    dispose() {
        if (VERBOSE) console.log("called dispose on effects holder");
        this.#in.disconnect();
        this.#in = null;
        this.#out.disconnect();
        this.#out = null;
        this.#wetGain.disconnect();
        this.#wetGain = null;
        this.#dryGain.disconnect();
        this.#dryGain = null;
        this.#monitor.release("fxholder");
    }

}

// ----------------------------------------------------------------
// Reverb - convolutional reverb
// ----------------------------------------------------------------

export class Reverb {

    #context
    #monitor
    #isValid
    #convolver

    /**
     * Creates an instance of Reverb.
     * @param {AudioContext} ctx - The audio context for the reverb effect.
     * @param {Object} monitor - The monitor object to track the reverb effect.
     */
    constructor(ctx, monitor) {
        if (VERBOSE) console.log("Making a Reverb");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#isValid = false;
        // monitor
        this.#monitor.retain("reverb");
        this.#convolver = ctx.createConvolver();
    }

    /**
     * Loads an impulse response from a file for the reverb effect.
     * @param {string} filename - The filename of the impulse response.
     */
    async load(filename) {
        const impulseResponse = await this.getImpulseResponseFromFile(filename);
        if (this.#isValid) {
            this.#convolver.buffer = impulseResponse;
        }
    }

    /**
     * Retrieves an impulse response from a file.
     * @param {string} filename - The filename of the impulse response.
     * @returns {AudioBuffer} The decoded audio data.
     */
    async getImpulseResponseFromFile(filename) {
        try {
            let reply = await fetch(`/bleep_audio/impulses/${filename}`);
            this.#isValid = true;
            return this.#context.decodeAudioData(await reply.arrayBuffer());
        } catch (err) {
            this.#isValid = false;
            if (VERBOSE) console.log("unable to load the impulse response file called " + filename);
        }
    }

    /**
     * Calculates the time it takes for an input signal to fade out.
     * @returns {number} The duration of the impulse response, representing fade out time.
     */
    timeToFadeOut() {
        // the time an input to this reverb takes to fade out is equal to the duration
        // of the impulse response used
        return this.#convolver.buffer.duration;
    }

    /**
     * Getter for the convolver input node.
     * @returns {ConvolverNode} The convolver node used as the input.
     */
    get in() {
        return this.#convolver;
    }

    /**
     * Getter for the convolver output node.
     * @returns {ConvolverNode} The convolver node used as the output.
     */
    get out() {
        return this.#convolver;
    }

    /**
     * Stops the reverb effect and cleans up resources.
     */
    stop() {
        this.#convolver.disconnect();
        this.#convolver = null;
        this.#monitor.release("reverb");
    }

}

// ----------------------------------------------------------------
// RolandChorus - chorus unit based on Roland Juno circuit
// ----------------------------------------------------------------

export class RolandChorus {

    static DEFAULT_CHORUS_RATE = 0.8;
    static DEFAULT_STEREO_SPREAD = 0.8;
    static DEFAULT_CHORUS_DEPTH = 0.001;
    static DEFAULT_DELAY_TIME = 0.0035;
    
    #in
    #out
    #lfo
    #leftDelay
    #rightDelay
    #leftPan
    #rightPan
    #leftGain
    #rightGain
    #leftMix
    #rightMix
    #monitor
    #context

    /**
     * Creates an instance of RolandChorus.
     * @param {AudioContext} ctx - The audio context for the chorus effect.
     * @param {Object} monitor - The monitor object to track the chorus effect.
     */
    constructor(ctx, monitor) {
        if (VERBOSE) console.log("Making a Chorus");
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("chorus");
        this.#makeGains();
        this.#makeDelayLines();
        this.#makeLFO();
        this.#makeConnections();
        this.#lfo.start();
    }

    #makeGains() {
        // input and output gains
        this.#in = this.#context.createGain();
        this.#in.gain.value = 1;
        this.#out = this.#context.createGain();
        this.#out.gain.value = 1;
        // depth controls
        this.#leftGain = this.#context.createGain();
        this.#leftGain.gain.value = RolandChorus.DEFAULT_CHORUS_DEPTH;
        this.#rightGain = this.#context.createGain();
        this.#rightGain.gain.value = -RolandChorus.DEFAULT_CHORUS_DEPTH;
        // left and right mixers
        this.#leftMix = this.#context.createGain();
        this.#leftMix.gain.value = 0.5;
        this.#rightMix = this.#context.createGain();
        this.#rightMix.gain.value = 0.5;
    }

    #makeLFO() {
        this.#lfo = this.#context.createOscillator();
        this.#lfo.type = "triangle";
        this.#lfo.frequency.value = RolandChorus.DEFAULT_CHORUS_RATE;
    }

    #makeDelayLines() {
        // left delay line
        this.#leftDelay = this.#context.createDelay();
        this.#leftDelay.delayTime.value = RolandChorus.DEFAULT_DELAY_TIME;
        this.#leftPan = this.#context.createStereoPanner();
        this.#leftPan.pan.value = -RolandChorus.DEFAULT_STEREO_SPREAD; // pan left
        // right delay line
        this.#rightDelay = this.#context.createDelay();
        this.#rightDelay.delayTime.value = RolandChorus.DEFAULT_DELAY_TIME;
        this.#rightPan = this.#context.createStereoPanner();
        this.#rightPan.pan.value = RolandChorus.DEFAULT_STEREO_SPREAD; // pan right
    }

    #makeConnections() {
        // connect left delay line
        this.#in.connect(this.#leftDelay);
        this.#leftDelay.connect(this.#leftMix);
        this.#in.connect(this.#leftMix);
        this.#leftMix.connect(this.#leftPan);
        this.#leftPan.connect(this.#out);
        // connect right delay line
        this.#in.connect(this.#rightDelay);
        this.#rightDelay.connect(this.#rightMix);
        this.#in.connect(this.#rightMix);
        this.#rightMix.connect(this.#rightPan);
        this.#rightPan.connect(this.#out);
        // connect gains on LFO to control depth
        this.#lfo.connect(this.#leftGain);
        this.#lfo.connect(this.#rightGain);
        this.#leftGain.connect(this.#leftDelay.delayTime);
        this.#rightGain.connect(this.#rightDelay.delayTime);
    }

    /**
     * Calculates the time it takes for the chorus effect to fade out.
     * @returns {number} The estimated fade out time.
     */
    timeToFadeOut() {
        // delay line is very short for a chorus, this will cover it
        return 0.05;
    }

    /**
    * Getter for the input gain node.
    * @returns {GainNode} The input gain node.
    */
    get in() {
        return this.#in;
    }

    /**
    * Getter for the output gain node.
    * @returns {GainNode} The output gain node.
    */
    get out() {
        return this.#out;
    }

    /**
     * Sets the depth of the chorus effect. Depth controls the intensity of the modulation.
     * @param {number} d - The depth value, typically between 0 and 1.
     */
    set depth(d) {
        this.#leftGain.gain.value = d / 1000;   // normal phase on left ear
        this.#rightGain.gain.value = -d / 1000; // phase invert on right ear
    }

    /**
     * Sets the stereo spread of the chorus effect. Spread controls the stereo separation of the effect.
     * @param {number} s - The spread value, typically between 0 (mono) and 1 (full stereo).
     */
    set spread(s) {
        this.#leftPan.pan.value = -s;
        this.#rightPan.pan.value = s;
    }

    /**
     * Sets the rate of the chorus effect. Rate controls the speed of the modulation.
     * @param {number} r - The rate value, in Hz, typically between 0.01 and 15.
     */
    set rate(r) {
        this.#lfo.frequency.value = Utility.clamp(r, 0.01, 15);
    }

    /**
     * Stops the chorus effect and cleans up resources.
     */
    stop() {
        this.#lfo.stop();
        this.#in.disconnect();
        this.#in = null;
        this.#out.disconnect();
        this.#in = null;
        this.#leftDelay.disconnect();
        this.#leftDelay = null;
        this.#rightDelay.disconnect();
        this.#rightDelay = null;
        this.#leftPan.disconnect();
        this.#leftPan = null;
        this.#rightPan.disconnect();
        this.#rightPan = null;
        this.#leftGain.disconnect();
        this.#leftGain = null;
        this.#rightGain.disconnect();
        this.#rightGain = null;
        this.#leftMix.disconnect();
        this.#leftMix = null;
        this.#rightMix.disconnect();
        this.#rightMix = null;
        this.#monitor.release("chorus");
    }
}

// ----------------------------------------------------------------
// StereoDelay
// ----------------------------------------------------------------

export class StereoDelay {

    static LOWEST_AMPLITUDE = 0.01;
    static DEFAULT_SPREAD = 0.95;
    static DEFAULT_LEFT_DELAY = 0.25;
    static DEFAULT_RIGHT_DELAY = 0.5;
    static DEFAULT_FEEDBACK = 0.4;

    #monitor
    #in
    #out
    #leftDelay
    #rightDelay
    #leftPan
    #rightPan
    #leftFeedbackGain
    #rightFeedbackGain
    #feedback

     /**
     * Creates an instance of StereoDelay.
     * @param {AudioContext} ctx - The audio context for the delay effect.
     * @param {Object} monitor - The monitor object to track the delay effect.
     */
    constructor(ctx, monitor) {
        if (VERBOSE) console.log("Making a Delay");

        this.#monitor = monitor;
        this.#monitor.retain("delay");

        this.#in = ctx.createGain();
        this.#in.gain.value = 1;

        this.#out = ctx.createGain();
        this.#out.gain.value = 1;

        this.#leftDelay = ctx.createDelay();
        this.#leftDelay.delayTime.value = StereoDelay.DEFAULT_LEFT_DELAY;

        this.#leftPan = ctx.createStereoPanner();
        this.#leftPan.pan.value = -StereoDelay.DEFAULT_SPREAD; // pan this delay line to the left

        this.#rightDelay = ctx.createDelay();
        this.#rightDelay.delayTime.value = StereoDelay.DEFAULT_RIGHT_DELAY;

        this.#rightPan = ctx.createStereoPanner();
        this.#rightPan.pan.value = StereoDelay.DEFAULT_SPREAD; // pan this delay line to the left

        this.#feedback = StereoDelay.DEFAULT_FEEDBACK;
        this.#leftFeedbackGain = ctx.createGain();
        this.#leftFeedbackGain.gain.value = this.#feedback;

        this.#rightFeedbackGain = ctx.createGain();
        this.#rightFeedbackGain.gain.value = this.#feedback;

        // connect up left side

        this.#in.connect(this.#leftDelay);
        this.#leftDelay.connect(this.#leftFeedbackGain);
        this.#leftDelay.connect(this.#leftPan);
        this.#leftPan.connect(this.#out);
        this.#leftFeedbackGain.connect(this.#leftDelay);

        // connect up right side

        this.#in.connect(this.#rightDelay);
        this.#rightDelay.connect(this.#rightFeedbackGain);
        this.#rightDelay.connect(this.#rightPan);
        this.#rightPan.connect(this.#out);
        this.#rightFeedbackGain.connect(this.#rightDelay);

    }

    /**
     * Sets the stereo spread of the delay effect.
     * @param {number} s - The spread value, controlling the stereo separation.
     */
    set spread(s) {
        this.#leftPan.pan.value = -s; 
        this.#rightPan.pan.value = s; 
    }

    /**
     * Sets the delay time for the left channel.
     * @param {number} d - The delay time in seconds for the left channel.
     */
    set leftDelay(d) {
        this.#leftDelay.delayTime.value = d;
    }

    /**
     * Sets the delay time for the right channel.
     * @param {number} d - The delay time in seconds for the right channel.
     */
    set rightDelay(d) {
        this.#rightDelay.delayTime.value = d;
    }

    /**
     * Sets the feedback amount for the delay effect.
     * @param {number} f - The feedback level, typically between 0 and 1.
     */
    set feedback(f) {
        this.#feedback = f;
        this.#leftFeedbackGain.gain.value = this.#feedback;
        this.#rightFeedbackGain.gain.value = this.#feedback;
    }

     /**
     * Calculates the time it takes for the delay effect to fade out.
     * @returns {number} The estimated fade out time in seconds.
     */
    timeToFadeOut() {
        // work out how long the delay line will take to fade out (exponential decay)
        const m = Math.max(this.#leftDelay.delayTime.value,this.#rightDelay.delayTime.value);
        const n = Math.log(StereoDelay.LOWEST_AMPLITUDE)/Math.log(this.#feedback);
        return m*n;
    }

    /**
    * Getter for the input gain node.
    * @returns {GainNode} The input gain node.
    */
    get in() {
        return this.#in;
    }

    /**
    * Getter for the output gain node.
    * @returns {GainNode} The output gain node.
    */
    get out() {
        return this.#out;
    }

    /**
     * Stops the delay and cleans up.
     */
    stop() {
        this.#in.disconnect();
        this.#in = null;
        this.#out.disconnect();
        this.#out = null;
        this.#monitor.release("delay");
        this.#leftDelay.disconnect();
        this.#leftDelay = null;
        this.#rightDelay.disconnect();
        this.#rightDelay = null;
        this.#leftPan.disconnect();
        this.#leftPan = null;
        this.#rightPan.disconnect();
        this.#rightPan = null;
        this.#leftFeedbackGain.disconnect();
        this.#leftFeedbackGain = null;
        this.#rightFeedbackGain.disconnect();
        this.#rightFeedbackGain = null;
    }

}

// ----------------------------------------------------------------
// EffectsChain - represents a chain of audio effects
// ----------------------------------------------------------------

export class EffectsChain {

    #context
    #monitor
    #in
    #out
    #tail
    #holders
    #disconnectPause

    /**
     * Creates an instance of EffectsChain.
     * @param {AudioContext} ctx - The audio context for the effects chain.
     * @param {Object} monitor - The monitor object to track the effects chain.
     */
    constructor(ctx, monitor) {
        if (VERBOSE) console.log("Making an Effects Chain");
        this.#holders = [];
        this.#context = ctx;
        this.#monitor = monitor;
        this.#monitor.retain("fxchain");
        this.#in = ctx.createGain();
        this.#in.gain.value = 1;
        this.#out = ctx.createGain();
        this.#out.gain.value = 1;
        this.#tail = null;
        // maximum time in seconds we must wait before disconnecting an effects chain
        this.#disconnectPause = 0;
    }

    /**
     * Adds an effect to the chain.
     * @param {Object} effect - The effect object to add to the chain.
     * @param {number} mixLevel - The mix level for the effect.
     * @param {number} outputLevel - The output level for the effect.
     */
    add(effect, mixLevel, outputLevel) {
        const holder = new EffectsHolder(this.#context, effect, this.#monitor, mixLevel, outputLevel);
        // store a reference to this holder so we can dispose of it later
        this.#holders.push(holder);
        if (VERBOSE) console.log("Added a serial effect");
        if (this.#tail) {
            this.#tail.disconnect(this.#out);
            this.#tail.connect(holder.in);
        } else {
            this.#in.connect(holder.in);
        }
        holder.out.connect(this.#out);
        this.#tail = holder.out;
        // update the time to wait before disconnecting
        // since some effects (delay, reverb) will need time to fade out
        this.#disconnectPause += effect.timeToFadeOut();
    }

    /**
     * Sets the input level of the effects chain.
     * @param {number} v - The value to set the input gain level.
     */
    set inputLevel(v) {
        this.#in.gain.value = v;
    }

    /**
     * Sets the output level of the effects chain.
     * @param {number} v - The value to set the output gain level.
     */
    set outputLevel(v) {
        this.#out.gain.value = v;
    }

    /**
    * Getter for the input gain node.
    * @returns {GainNode} The input gain node.
    */
    get in() {
        return this.#in;
    }

    /**
    * Getter for the output gain node.
    * @returns {GainNode} The output gain node.
    */
    get out() {
        return this.#out;
    }

    /**
     * Stops the effects chain after a specified delay and cleans up.
     * @param {number} when - The time at which to stop the effects chain.
     */
    stop(when) {
        let stopTime = when - this.#context.currentTime;
        if (stopTime < 0) stopTime = 0;
        setTimeout(() => {
            if (VERBOSE) console.log("stopping and killing the effects chain");
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
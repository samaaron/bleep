const VERBOSE = false;

// mapping between grammar names for modules and class names

const moduleClasses = {
  "SAW-OSC": "SawOsc",
  "SIN-OSC": "SinOsc",
  "TRI-OSC": "TriOsc",
  "SQR-OSC": "SquareOsc",
  "RAND-OSC" : "RandomOsc",
  "PULSE-OSC": "PulseOsc",
  LFO: "LFO",
  PAN: "Panner",
  NOISE: "Noise",
  LPF: "LowpassFilter",
  HPF: "HighpassFilter",
  VCA: "Amplifier",
  SHAPER: "Waveshaper",
  ADSR: "Envelope",
  DECAY: "Decay",
  AUDIO: "Audio",
  DELAY: "Delay",
};

const MIDDLE_C = 261.63; // Hz

// ------------------------------------------------------------
// Prototype oscillator class
// ------------------------------------------------------------

Oscillator = class {
  // Note that if these are declared #private
  // then they won't be visible to subclasses of Oscillator
  _osc;
  _context;
  _monitor;

  constructor(ctx, monitor) {
    this._context = ctx;
    this._osc = ctx.createOscillator(ctx);
    this._osc.frequency.value = MIDDLE_C;
    this._monitor = monitor;
    this._monitor.retain("osc");
  }

  set detune(n) {
    this._osc.detune.value = n;
  }

  get detune() {
    return this._osc.detune.value;
  }

  get pitch() {
    return this._osc.frequency.value;
  }

  set pitch(n) {
    this._osc.frequency.value = n;
  }

  get out() {
    return this._osc;
  }

  get pitchCV() {
    return this._osc.frequency;
  }

  // quick fix
  // TODO : this will not work for pulse oscillator @guyjbrown
  bend(startFreq,startTime,endFreq,endTime) {
    this._osc.frequency.setValueAtTime(startFreq,startTime);
    this._osc.frequency.exponentialRampToValueAtTime(endFreq,endTime);
  }

  start(tim) {
    if (VERBOSE) console.log("starting oscillator");
    this._osc.start(tim);
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Oscillator");
    this._osc.stop(tim);
    let stopTime = tim - this._context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Oscillator");
      this._osc.disconnect();
      this._osc = null;
      this._context = null;
      this._monitor.release("osc");
    }, (stopTime + 0.1) * 1000);
  }
};

let moduleContext = {};

// ------------------------------------------------------------
// LFO with adjustable phase
// ------------------------------------------------------------

moduleContext.LFO = class {
  #sinOsc;
  #cosOsc;
  #sinGain;
  #cosGain;
  #mixer;
  #freqHz;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#freqHz = 5; // Hz

    this.#sinOsc = ctx.createOscillator();
    this.#sinOsc.type = "sine";
    this.#sinOsc.frequency.value = this.#freqHz;

    this.#cosOsc = ctx.createOscillator();
    this.#cosOsc.type = "sine";
    this.#cosOsc.frequency.value = this.#freqHz;

    this.#sinGain = ctx.createGain();
    this.#cosGain = ctx.createGain();
    this.#mixer = ctx.createGain();

    this.#sinOsc.connect(this.#sinGain);
    this.#cosOsc.connect(this.#cosGain);
    this.#sinGain.connect(this.#mixer);
    this.#cosGain.connect(this.#mixer);
    this.#monitor = monitor;
    this.#monitor.retain("lfo");
  }

  set phase(p) {
    this.#sinGain.gain.value = Math.cos(p);
    this.#cosGain.gain.value = Math.sin(p);
  }

  get pitch() {
    return this.#freqHz;
  }

  set pitch(n) {
    this.#freqHz = n;
    this.#sinOsc.frequency.value = this.#freqHz;
    this.#cosOsc.frequency.value = this.#freqHz;
  }

  get out() {
    return this.#mixer;
  }

  start(tim) {
    this.#sinOsc.start(tim);
    this.#cosOsc.start(tim);
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping LFO");
    this.#sinOsc.stop(tim);
    this.#cosOsc.stop(tim);
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting LFO");
      this.#sinOsc.disconnect();
      this.#cosOsc.disconnect();
      this.#sinGain.disconnect();
      this.#cosGain.disconnect();
      this.#mixer.disconnect();
      this.#sinOsc = null;
      this.#cosOsc = null;
      this.#sinGain = null;
      this.#cosGain = null;
      this.#mixer = null;
      this.#context = null;
      this.#monitor.release("lfo");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// Stereo panner
// ------------------------------------------------------------

moduleContext.Panner = class {
  #pan;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#pan = ctx.createStereoPanner();
    this.#monitor = monitor;
    this.#monitor.retain("panner");
  }

  // stereo position between -1 and 1
  set angle(p) {
    this.#pan.pan.value = p;
  }

  // stereo position between -1 and 1
  get angle() {
    return this.#pan.pan.value;
  }

  get angleCV() {
    return this.#pan.pan;
  }

  get in() {
    return this.#pan;
  }

  get out() {
    return this.#pan;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Panner");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Panner");
      this.#pan.disconnect();
      this.#pan = null;
      this.#context = null;
      this.#monitor.release("panner");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// Delay line
// ------------------------------------------------------------

moduleContext.Delay = class {
  #delay;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#delay = ctx.createDelay(10);
    this.#monitor = monitor;
    this.#monitor.retain("delay");
  }

  set lag(t) {
    this.#delay.delayTime.value = t;
  }

  get lag() {
    return this.#delay.delayTime.value;
  }

  get lagCV() {
    return this.#delay.delayTime;
  }

  get in() {
    return this.#delay;
  }

  get out() {
    return this.#delay;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Delay");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Delay");
      this.#delay.disconnect();
      this.#delay = null;
      this.#context = null;
      this.#monitor.release("delay");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// Pulse oscillator function
// this is quite a bit more complex than the standard oscillator
// to make a pulse we need to compute the difference of two saws
// https://speakerdeck.com/stevengoldberg/pulse-waves-in-webaudio?slide=13

moduleContext.PulseOsc = class extends Oscillator {
  //#monitor;
  #osc2;
  #detuneNode;
  #freqNode;
  #out;
  #inverter;
  #delay;
  #freqHz;
  #pulsewidth;
  #pwm;

  constructor(ctx, monitor) {
    super(ctx, monitor);

    // set the parameters of oscillator 1
    // we set the oscillator value to 0 to avoid an offset since we will control the
    // frequency of the two oscillatoes via the ConstantSourceNode
    this.#freqHz = MIDDLE_C;
    this._osc.frequency.value = 0;
    this._osc.type = "sawtooth";

    // set the parameters of oscillator 2
    this.#osc2 = ctx.createOscillator();
    this.#osc2.frequency.value = 0;
    this.#osc2.type = "sawtooth";

    // set the initial pulsewidth to 50%
    this.#pulsewidth = 0.5;

    // the inverter, which subtracts one saw from the other
    this.#inverter = ctx.createGain(ctx);
    this.#inverter.gain.value = -1;

    // constant source node to change frequency and detune of both oscillators
    this.#freqNode = new ConstantSourceNode(ctx);
    this.#detuneNode = new ConstantSourceNode(ctx);

    // connect them up
    this.#freqNode.connect(this._osc.frequency);
    this.#freqNode.connect(this.#osc2.frequency);
    this.#detuneNode.connect(this._osc.detune);
    this.#detuneNode.connect(this.#osc2.detune);

    // sum the outputs into this gain
    this.#out = ctx.createGain();
    this.#out.gain.value = 0.5;

    // the delay is a fraction of the period, given by the pulse width
    this.#delay = ctx.createDelay();
    this.#delay.delayTime.value = this.#pulsewidth / this.#freqHz;

    // pulse width modulation
    this.#pwm = ctx.createGain();
    this.#pwm.gain.value = 1 / this.#freqHz;
    this.#pwm.connect(this.#delay.delayTime);

    // connect everything else
    this._osc.connect(this.#delay);
    this.#delay.connect(this.#inverter);
    this.#inverter.connect(this.#out);
    this.#osc2.connect(this.#out);
  }

  // set the pulse width which should be in the range [0,1]
  // a width of 0.5 corresponds to a square wave
  // we keep track of the frequency in a variable since we need to set the frequency
  // of the oscillator to zero and set frequency through the constantsource node
  // it would cause division by zero issues if used directly
  set pulsewidth(w) {
    this.#pulsewidth = w;
    this.#delay.delayTime.value = w / this.#freqHz;
  }

  // get the pulse width value
  get pulsewidth() {
    return this.#pulsewidth;
  }

  // set the detune of both oscillators through the constant source node
  set detune(n) {
    this.#detuneNode.offset.value = n;
  }

  // set the pitch
  // when the pitch changes, we need to update the maximum delay time which is 1/f
  // and the current delay which is pulsewidth/f
  set pitch(f) {
    this.#freqHz = f;
    this.#pwm.gain.value = 1 / this.#freqHz;
    this.#delay.delayTime.value = this.#pulsewidth / f;
    this.#freqNode.offset.value = f;
  }

  // we control the frequency of the pulse oscillator through the 
  // constant source node, which is linked to both saw oscs
  bend(startFreq,startTime,endFreq,endTime) {
    this.#freqNode.offset.setValueAtTime(startFreq,startTime);
    this.#freqNode.offset.exponentialRampToValueAtTime(endFreq,endTime);
  }

  // get the output node
  get out() {
    return this.#out;
  }

  // the pulsewidth CV for PWM which takes an input through a gain node and scales it to
  // the maximum of the period
  // this means that we can set pulsewidth to 0.5 and then CV should be in the range [0,0.5]
  get pulsewidthCV() {
    return this.#pwm;
  }

  // the pitch CV is the constant source node offset connected to both oscillator frequencies
  get pitchCV() {
    return this.#freqNode.offset;
  }

  // start everything, including the source nodes
  start(tim) {
    this.#freqNode.start(tim);
    this.#detuneNode.start(tim);
    this._osc.start(tim);
    this.#osc2.start(tim);
  }

  // stop everything
  stop(tim) {
    if (VERBOSE) console.log("stopping Pulse");
    this._osc.stop(tim);
    this.#osc2.stop(tim);
    this.#freqNode.stop(tim);
    this.#detuneNode.stop(tim);
    let stopTime = tim - this._context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Pulse");
      this._osc.disconnect();
      this.#osc2.disconnect();
      this.#freqNode.disconnect();
      this.#detuneNode.disconnect();
      this.#out.disconnect();
      this.#delay.disconnect();
      this.#inverter.disconnect();
      this.#pwm.disconnect();

      this.#osc2 = null;
      this.#freqNode = null;
      this.#detuneNode = null;
      this.#out = null;
      this.#delay = null;
      this.#inverter = null;
      this.#pwm = null;
      this._osc = null;
      this._context = null;
      this._monitor.release("osc");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// Saw oscillator class
// ------------------------------------------------------------

moduleContext.SawOsc = class extends Oscillator {
  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._osc.type = "sawtooth";
  }
};

// ------------------------------------------------------------
// Sin oscillator class
// ------------------------------------------------------------

moduleContext.SinOsc = class extends Oscillator {
  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._osc.type = "sine";
  }
};

// ------------------------------------------------------------
// Triangle oscillator class
// ------------------------------------------------------------

moduleContext.TriOsc = class extends Oscillator {
  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._osc.type = "triangle";
  }
};

// ------------------------------------------------------------
// Square oscillator class
// ------------------------------------------------------------

moduleContext.SquareOsc = class extends Oscillator {
  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._osc.type = "square";
  }
};

// ------------------------------------------------------------
// Random oscillator class
// ------------------------------------------------------------

moduleContext.RandomOsc = class extends Oscillator {

  // real parts for random sequence
  static REAL_PARTS = new Float32Array([9.1182, 1.1314, -3.7047, -1.5283, -1.0751, 0.0700, 3.2826, 3.6116, -5.5772, -2.6959, 2.6466, -1.8377, 2.1301, 0.9041, -1.5017, -4.2249, -1.0005, -0.4352, 4.5624, -6.7144, 2.4735, -2.0083, -2.6985, 3.7056, -2.2746, 5.1290, -7.3179, 2.4413, 4.1436, 0.3962, -4.8453, 2.1462, 2.5211, 2.1462, -4.8453, 0.3962, 4.1436, 2.4413, -7.3179, 5.1290, -2.2746, 3.7056, -2.6985, -2.0083, 2.4735, -6.7144, 4.5624, -0.4352, -1.0005, -4.2249, -1.5017, 0.9041, 2.1301, -1.8377, 2.6466, -2.6959, -5.5772, 3.6116, 3.2826, 0.0700, -1.0751, -1.5283, -3.7047, 1.1314]);

  // imaginary parts for random sequence
  static IMAG_PARTS = new Float32Array([0.0000, 1.6620, 4.1186, 5.8102, -1.8278, -0.6848, 0.7658, -2.5074, -5.5043, -3.6768, -4.1541, -3.6705, 2.7696, -5.5667, 1.8004, 3.6096, 5.5857, 5.1045, 1.1952, 1.6681, 2.3166, -3.3849, -3.2703, 0.2231, -0.6119, 1.1657, -0.3912, -2.2402, -1.4960, -2.8728, -9.5067, 0.2702, 0.0000, -0.2702, 9.5067, 2.8728, 1.4960, 2.2402, 0.3912, -1.1657, 0.6119, -0.2231, 3.2703, 3.3849, -2.3166, -1.6681, -1.1952, -5.1045, -5.5857, -3.6096, -1.8004, 5.5667, -2.7696, 3.6705, 4.1541, 3.6768, 5.5043, 2.5074, -0.7658, 0.6848, 1.8278, -5.8102, -4.1186, -1.6620]);
  
  constructor(ctx,monitor) {
    super(ctx,monitor);
    // oscillator with a wavetable containing a random sequence
    const wave = ctx.createPeriodicWave(moduleContext.RandomOsc.REAL_PARTS, moduleContext.RandomOsc.IMAG_PARTS);
    this._osc.setPeriodicWave(wave);
  }
}


// ------------------------------------------------------------
// Noise generator class
// for reasons of efficiency we loop a 2-second buffer of noise rather than generating
// random numbers for every sample
// https://noisehack.com/generate-noise-web-audio-api/
// TODO actually this is still very inefficient - we should share a noise generator across
// all players
// ------------------------------------------------------------

moduleContext.Noise = class NoiseGenerator {
  #noise;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    let bufferSize = 2 * ctx.sampleRate;
    let noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    let data = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1;
    this.#noise = ctx.createBufferSource();
    this.#noise.buffer = noiseBuffer;
    this.#noise.loop = true;
    this.#monitor = monitor;
    this.#monitor.retain("noise");
  }

  get out() {
    return this.#noise;
  }

  start(tim) {
    this.#noise.start(tim);
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Noise");
    this.#noise.stop(tim);
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Noise");
      this.#noise.disconnect();
      this.#noise = null;
      this.#context = null;
      this.#monitor.release("noise");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// LPF class
// ------------------------------------------------------------

moduleContext.LowpassFilter = class {
  #filter;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#monitor = monitor;
    this.#filter = ctx.createBiquadFilter();
    this.#filter.frequency.value = 1000;
    this.#filter.Q.value = 1;
    this.#filter.type = "lowpass";
    this.#monitor.retain("lowpass");
  }

  get cutoff() {
    return this.#filter.frequency.value;
  }

  set cutoff(f) {
    this.#filter.frequency.value = f;
  }

  get cutoffCV() {
    return this.#filter.frequency;
  }

  get resonance() {
    return this.#filter.Q.value;
  }

  set resonance(r) {
    this.#filter.Q.value = r;
  }

  get in() {
    return this.#filter;
  }

  get out() {
    return this.#filter;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping LPF");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting LPF");
      this.#filter.disconnect();
      this.#filter = null;
      this.#context = null;
      this.#monitor.release("lowpass");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// HPF class
// ------------------------------------------------------------

moduleContext.HighpassFilter = class {
  #filter;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#monitor = monitor;
    this.#filter = ctx.createBiquadFilter();
    this.#filter.frequency.value = 1000;
    this.#filter.Q.value = 1;
    this.#filter.type = "highpass";
    this.#monitor.retain("highpass");
  }

  get cutoff() {
    return this.#filter.frequency.value;
  }

  set cutoff(f) {
    this.#filter.frequency.value = f;
  }

  get cutoffCV() {
    return this.#filter.frequency;
  }

  get resonance() {
    return this.#filter.Q.value;
  }

  set resonance(r) {
    this.#filter.Q.value = r;
  }

  get in() {
    return this.#filter;
  }

  get out() {
    return this.#filter;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping HPF");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting HPF");
      this.#filter.disconnect();
      this.#filter = null;
      this.#context = null;
      this.#monitor.release("highpass");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// ADSR class
// ------------------------------------------------------------

moduleContext.Envelope = class {
  #attack;
  #decay;
  #sustain;
  #release;
  #level;
  #controlledParam;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#attack = 0.1;
    this.#decay = 0.5;
    this.#sustain = 0.5;
    this.#release = 0.1;
    this.#level = 1.0;
    this.#monitor = monitor;
  }

  set attack(v) {
    this.#attack = v;
  }

  set decay(v) {
    this.#decay = v;
  }

  set sustain(v) {
    this.#sustain = v;
  }

  get release() {
    return this.#release;
  }

  set release(v) {
    this.#release = v;
  }

  set level(v) {
    this.#level = v;
    // this next bit only takes effect when the audio network is connected and playing
    if (this.#controlledParam != undefined)
      this.#controlledParam.setValueAtTime(v, this.#context.currentTime);
  }

  apply(param, when, duration) {
    // the duration corresponds to the time between a note on and note off, the release time is extra
    // TODO this will generate an numerical error if the attack or decay is zero
    this.#controlledParam = param;
    if (duration <= this.#attack) { 
      // AR - if the duration is shorter than the attack, work out how far into the
      // attack we get, linear ramp to there, and then go to the release
      const attackLevel = duration / this.#attack * this.#level;
      param.setValueAtTime(0, when);
      param.linearRampToValueAtTime(attackLevel, when + duration);
      param.linearRampToValueAtTime(0, when + duration + this.#release);
    } else if (duration <= (this.#attack + this.#decay)) {
      // ADR - if the duration is shorter than the decay, do the attack as normal and work out
      // how far we get through the decay, linear ramp to there, and then go to release
      const decayLevel = this.#level - (this.#level - this.#sustain) * (duration - this.#attack) / this.#decay;
      param.setValueAtTime(0, when);
      param.linearRampToValueAtTime(this.#level, when + this.#attack);
      param.linearRampToValueAtTime(decayLevel, when + duration);
      param.linearRampToValueAtTime(0, when + duration + this.#release);
    } else {
      // ADSR - the duration must be longer than the sum of the attack and decay times, so this is a
      // straightforward ADSR envelope, linear ramp to attack, linear ramp down to sustain level, 
      // hold there for note duration and then go to the release 
      param.setValueAtTime(0, when);
      param.linearRampToValueAtTime(this.#level, when + this.#attack);
      param.linearRampToValueAtTime(this.#sustain, when + this.#attack + this.#decay);
      param.setValueAtTime(this.#sustain, when + duration);
      param.linearRampToValueAtTime(0, when + duration + this.#release);
    }
  }

};

// ------------------------------------------------------------
// Decay class - linear attack and exponential decay envelope
// ------------------------------------------------------------

moduleContext.Decay = class {
  #attack;
  #decay;
  #level;
  #monitor;

  constructor(ctx, monitor) {
    this.#attack = 0.1;
    this.#decay = 0.5;
    this.#level = 1.0;
    this.#monitor = monitor;
  }

  set attack(v) {
    this.#attack = v;
  }

  set decay(v) {
    this.#decay = v;
  }

  set level(v) {
    this.#level = v;
  }

  apply(param, when) {
    param.setValueAtTime(0, when);
    param.linearRampToValueAtTime(this.#level, when + this.#attack);
    param.exponentialRampToValueAtTime(
      0.0001,
      when + this.#attack + this.#decay
    );
  }
};

// ------------------------------------------------------------
// Waveshaper class
// ------------------------------------------------------------

moduleContext.Waveshaper = class {
  #shaper;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#shaper = ctx.createWaveShaper();
    this.#shaper.curve = this.makeDistortionCurve(100);
    this.#shaper.oversample = "4x";
    this.#monitor = monitor;
    this.#monitor.retain("shaper");
  }

  get in() {
    return this.#shaper;
  }

  get out() {
    return this.#shaper;
  }

  get fuzz() {
    return 0; // all that matters is that this returns a number
  }

  set fuzz(n) {
    this.#shaper.curve = this.makeDistortionCurve(n);
  }

  // this is a sigmoid function which is linear for k=0 and goes through (-1,-1), (0,0) and (1,1)
  // https://stackoverflow.com/questions/22312841/waveshaper-node-in-webaudio-how-to-emulate-distortion

  makeDistortionCurve(n) {
    const numSamples = 44100;
    const curve = new Float32Array(numSamples);
    //const deg = Math.PI / 180.0;
    for (let i = 0; i < numSamples; i++) {
      const x = (i * 2) / numSamples - 1;
      curve[i] = ((Math.PI + n) * x) / (Math.PI + n * Math.abs(x));
    }
    return curve;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Shaper");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Shaper");
      this.#shaper.disconnect();
      this.#shaper = null;
      this.#context = null;
      this.#monitor.release("shaper");
    }, (stopTime + 0.1) * 1000);
  }
};

// ------------------------------------------------------------
// Amplifier class
// ------------------------------------------------------------

moduleContext.Amplifier = class {
  #gain;
  #context;
  #monitor;

  constructor(ctx, monitor) {
    this.#context = ctx;
    this.#monitor = monitor;
    const gain = ctx.createGain();
    gain.gain.value = 1;
    this.#gain = gain;
    this.#monitor.retain("amp");
  }

  get in() {
    return this.#gain;
  }

  get out() {
    return this.#gain;
  }

  get level() {
    return this.#gain.gain.value;
  }

  set level(n) {
    this.#gain.gain.value = n;
  }

  get levelCV() {
    return this.#gain.gain;
  }

  stop(tim) {
    if (VERBOSE) console.log("stopping Amplifier");
    let stopTime = tim - this.#context.currentTime;
    if (stopTime < 0) stopTime = 0;
    setTimeout(() => {
      if (VERBOSE) console.log("disconnecting Amplifier");
      this.#gain.disconnect();
      this.#gain = null;
      this.#context = null;
      this.#monitor.release("amp");
    }, (stopTime + 0.1) * 1000);
  }
};

export function getModuleInstance(type, ctx, monitor) {
  let a = moduleContext[moduleClasses[type]];
  let b = new a(ctx, monitor);
  return new moduleContext[moduleClasses[type]](ctx, monitor);
}

import { getModuleInstance } from "./modules";

const VERBOSE = false;

export default Player = class {
  #node;
  #context;
  #generator;
  #params;
  #monitor;

  constructor(ctx, generator, pitchHz, level, duration, params, monitor) {
    console.log(`Hello I am playing a note with duration of ${duration}`);
    this.#context = ctx;
    this.#generator = generator;
    this.#params = { ...generator.defaults, ...params };
    this.#node = {};
    this.#monitor = monitor;
    // add the pitch and level to the parameters
    this.#params.pitch = pitchHz;
    this.#params.level = level;
    this.#params.duration = duration;
    // create the webaudio network in three steps

    this.#createModules();
    this.#createPatches();
    this.#applyTweaks();
  }

  #createModules() {
    // make a webaudio object for each node
    for (let m of this.#generator.modules) {
      let i = getModuleInstance(m.type, this.#context, this.#monitor);
      this.#node[m.id] = i;
    }
    // we always need an audio object for output
    this.#node["audio"] = getModuleInstance(
      "VCA",
      this.#context,
      this.#monitor
    );
  }

  // connect all the patch cables
  #createPatches() {
    for (let p of this.#generator.patches) {
      let fromModule = this.#node[p.from.id];
      let toModule = this.#node[p.to.id];
      fromModule[p.from.param].connect(toModule[p.to.param]);
    }
  }

  // do all the parameter tweaks
  #applyTweaks() {
    for (let t of this.#generator.tweaks) {
      let obj = this.#node[t.id];

      let val = this.#evaluatePostfix(t.expression);
      obj[t.param] = val;
    }
  }

  // apply one tweak now as an instantaneous change
  // you can only do this to parameters that have been identified as mutable
  applyTweakNow(param, value) {
    // is the parameter mutable?
    if (this.#generator.mutable[param] === false) return;
    // update the parameter set with the value
    this.#params[param] = value;
    // update any expressions that use the tweaked parameter
    for (let t of this.#generator.tweaks) {
      if (t.expression.includes(`param.${param}`)) {
        let obj = this.#node[t.id];
        let val = this.#evaluatePostfix(t.expression);
        obj[t.param] = val;
      }
    }
  }

  start(when) {
    // apply the envelopes
    for (let e of this.#generator.envelopes) {
      let env = this.#node[e.from.id];
      let obj = this.#node[e.to.id];

      env.apply(obj[e.to.param], when);
    }
    // start all the nodes that have a start function
    Object.values(this.#node).forEach((m) => {
      m.start?.(when);
    });
  }

  // stop the webaudio network right now
  stopImmediately() {
    if (VERBOSE) console.log("stopping immediately");
    let now = context.currentTime;
    Object.values(this.#node).forEach((m) => {
      m.stop?.(now);
    });
  }

  // stop the webaudio network only after the release phase of envelopes has completed
  stopAfterRelease(when) {
    if (VERBOSE) console.log("stopping after release");
    let longestRelease = 0;
    Object.values(this.#node).forEach((m) => {
      if (m.release) {
        m.releaseOnNoteOff(when);
        if (m.release > longestRelease) longestRelease = m.release;
      }
    });
    // stop after the longest release time
    Object.values(this.#node).forEach((m) => {
      m.stop?.(when + longestRelease);
    });
  }

  get out() {
    return this.#node.audio.out;
  }

  #scaleValue(low, high, min, max, p) {
    return min + ((p - low) * (max - min)) / (high - low);
  }

  #randomBetween(min, max) {
    return min + Math.random() * (max - min);
  }

  #isNumber(t) {
    return !isNaN(parseFloat(t)) && isFinite(t);
  }

  #isIdentifier(t) {
    return typeof t === "string" && t.startsWith("param.");
  }

  // evaluate a parameter expression in postfix form
  #evaluatePostfix(expression) {
    let stack = [];

    const popOperand = () => {
      let op = stack.pop();

      if (this.#isIdentifier(op)) {
        op = this.#params[op.replace("param.", "")];
      }
      return op;
    };

    for (let t of expression) {
      if (this.#isNumber(t)) {
        stack.push(parseFloat(t));
      } else if (this.#isIdentifier(t)) {
        stack.push(t);
      } else if (t === "*" || t === "/" || t === "+" || t == "-") {
        let op2 = popOperand();
        let op1 = popOperand();
        switch (t) {
          case "*":
            stack.push(op1 * op2);
            break;
          case "/":
            stack.push(op1 / op2);
            break;
          case "+":
            stack.push(op1 + op2);
            break;
          case "-":
            stack.push(op1 - op2);
            break;
        }
      } else if (t === "log") {
        let op = popOperand();
        stack.push(Math.log(op));
      } else if (t === "exp") {
        let op = popOperand();
        stack.push(Math.exp(op));
      } else if (t === "random") {
        let op1 = stack.pop();
        let op2 = stack.pop();
        let r = this.#randomBetween(op2, op1);
        stack.push(r);
      } else if (t === "map") {
        let op1 = stack.pop();
        let op2 = stack.pop();
        let op3 = stack.pop();
        let control = op3.replace("param.", "");
        let minval = this.#generator.minima[control];
        let maxval = this.#generator.maxima[control];

        let s = this.#scaleValue(
          minval,
          maxval,
          op2,
          op1,
          this.#params[control]
        );
        stack.push(s);
      }
    }

    let result = stack[0];
    if (this.#isIdentifier(result)) {
      const param_id = result.replace("param.", "");
      return this.#params[param_id];
    }

    return result;
  }
};

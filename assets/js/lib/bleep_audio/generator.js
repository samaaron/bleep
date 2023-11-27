const MAX_MIDI_FREQ = 4186; // C8
const MIN_MIDI_FREQ = 27.5; // A0
const MAX_LEVEL = 1;
const MIN_LEVEL = 0;

// ------------------------------------------------------------
// Bleep SynthDef Web Audio Generator class
// ------------------------------------------------------------

export default class Generator {
  #id;
  #isValid;
  #hasWarning;
  #longname;
  #shortname;
  #version;
  #author;
  #doc;
  #modules;
  #patches;
  #tweaks;
  #envelopes;
  #parameters;
  #maxima;
  #minima;
  #defaults;
  #mutable;
  #errorString;
  #warningString;

  constructor(json) {
    const tree = JSON.parse(json);
    this.#id = tree.longname; // perhaps change this to tree.id
    this.#longname = tree.longname;
    this.#shortname = tree.shortname;
    this.#version = tree.version;
    this.#author = tree.author;
    this.#doc = tree.doc;
    this.#modules = tree.modules || [];
    this.#patches = tree.patches || [];
    this.#tweaks = tree.tweaks || [];
    this.#envelopes = tree.envelopes || [];
    this.#parameters = tree.parameters || [];
    this.#isValid = true;
    this.#hasWarning = false;
    this.#errorString = "";
    this.#warningString = "";
    // find the maxima and minima of all parameters and store them
    // but we need to store information about max/min pitch and level
    this.#maxima = {};
    this.#maxima.pitch = MAX_MIDI_FREQ;
    this.#maxima.level = MAX_LEVEL;
    this.#minima = {};
    this.#minima.pitch = MIN_MIDI_FREQ;
    this.#minima.level = MIN_LEVEL;
    this.#defaults = {};
    this.#mutable = {};
    for (let m of this.#parameters) {
      this.#mutable[m.name] = m.mutable === "yes";
      this.#maxima[m.name] = m.max;
      this.#minima[m.name] = m.min;
      this.#defaults[m.name] = m.default;
    }
    try {
      this.#checkForErrors();
    } catch (error) {
      this.#isValid = false;
      this.#errorString = error.message;
    }
    this.#checkForWarnings();
  }

  // check for errors

  #checkForErrors() {
    // nothing is patched
    if (this.#patches.length == 0)
      throw new Error("Bleep Generator error: nothing is patched");
    // no modules have been added
    if (this.#modules.length == 0)
      throw new Error("Bleep Generator error: no modules have been added");
    // nothing is patched to audio in
    if (!this.hasPatchTo("audio", "in"))
      throw new Error("Bleep Generator error: nothing is patched to audio.in");
  }

  // we might warn the user about some stuff, like nothing patched from keyboard.pitch

  #checkForWarnings() {
    // have the pitch and level been assigned to anything?
    let msg = "";
    for (let param of ["pitch", "level"]) {
      if (!this.hasTweakWithValue(`param.${param}`))
        msg += `Bleep Generator warning: you haven't assigned param.${param} to a control\n`;
    }
    // has something been patched to audio.in?
    if (this.hasPatchTo("audio", "in") == false)
      msg += `Bleep Generator warning: you haven't patched anything to audio.in\n`;
    // check that parameters have reasonable values
    for (let obj of this.#parameters) {
      if (obj.max < obj.min)
        msg += `Bleep Generator warning: max of parameter ${obj.name} is less than min\n`;
      if (obj.default < obj.min)
        msg += `Bleep Generator warning: default of parameter ${obj.name} is less than min\n`;
      if (obj.default > obj.max)
        msg += `Bleep Generator warning: default of parameter ${obj.name} is greater than max\n`;
    }
    // throw the warning if we have one
    if (msg.length > 0) this.throwWarning(msg);
  }

  // determine if this generator has a patch cable to the given node

  hasPatchTo(node, param) {
    return this.#patches.some(
      (val) => val.to.id === node && val.to.param === param
    );
  }

  // determine if this generator has a patch cable from the given node

  hasPatchFrom(node, param) {
    return this.#patches.some(
      (val) => val.from.id === node && val.from.param === param
    );
  }

  // check for a tweak with a given value (for keyboard checks)
  hasTweakWithValue(value) {
    return this.#tweaks.some((val) => val.expression.includes(value));
  }

  // register a warning message

  throwWarning(msg) {
    this.#hasWarning = true;
    this.#warningString = msg;
  }

  // get the id of the generator
  get id() {
    return this.#id;
  }

  // get the long name of the generator

  get longname() {
    return this.#longname;
  }

  // get the short name of the generator

  get shortname() {
    return this.#shortname;
  }

  // get the version of the generator

  get version() {
    return this.#version;
  }

  // get the author of the generator

  get author() {
    return this.#author;
  }

  // get the doc string of the generator

  get doc() {
    return this.#doc;
  }

  module(i) {
    return this.#modules[i];
  }

  patch(i) {
    return this.#patches[i];
  }

  tweak(i) {
    return this.#tweaks[i];
  }

  envelope(i) {
    return this.#envelopes[i];
  }

  get maxima() {
    return this.#maxima;
  }

  get minima() {
    return this.#minima;
  }

  get mutable() {
    return this.#mutable;
  }

  get modules() {
    return this.#modules;
  }

  // get the list of patch points

  get patches() {
    return this.#patches;
  }

  // get the list of tweaks

  get tweaks() {
    return this.#tweaks;
  }

  get envelopes() {
    return this.#envelopes;
  }


  // get the list of parameters

  get parameters() {
    return this.#parameters;
  }

  get defaults() {
    return this.#defaults;
  }

  // is the generator valid?

  get isValid() {
    return this.#isValid;
  }

  // did we have any warnings?

  get hasWarning() {
    return this.#hasWarning;
  }

  // get a string representing the error

  get errorString() {
    return this.#errorString;
  }

  // get a string representing the warning

  get warningString() {
    return this.#warningString;
  }
}

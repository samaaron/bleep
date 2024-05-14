export default class Monitor {

  static GAIN_NODE = "GainNode"
  static SOURCE_NODE = "SourceNode"
  static PAN_NODE = "StereoPannerNode"
  static LOWPASS_NODE = "BiquadFilterNode"

  #numNotes
  #fields

  constructor() {
    this.#numNotes = 0;
    this.#fields = {
      note: 0,
      osc: 0,
      amp: 0,
      lowpass: 0,
      highpass: 0,
      lfo: 0,
      panner: 0,
      delay: 0,
      noise: 0,
      shaper: 0,
      audio: 0,
      GainNode: 0,
      SourceNode: 0,
    }
  }

  retain(f) {
    this.#fields[f]++;
  }

  release(f) {
    this.#fields[f]--;
  }

  info() {
    let str = "";
    for (const key in this.#fields) {
      str += `${key} ${this.#fields[key]} : `;
    }
    return str;
  }
}

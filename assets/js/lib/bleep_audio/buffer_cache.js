export default class BleepBufferCache {
  #loaded_buffers = new Map();

  constructor() {

  }

  async load_buffer(url, ctx) {
    if (this.#loaded_buffers.has(url)) {
      return this.#loaded_buffers.get(url);
    }
    console.log("Fetching audio buffer", url);
    let response = await fetch(url);
    let array_buffer = await response.arrayBuffer();
    let audio_buffer = await ctx.decodeAudioData(array_buffer);
    this.#loaded_buffers.set(url, audio_buffer);
    return audio_buffer;
  }
}

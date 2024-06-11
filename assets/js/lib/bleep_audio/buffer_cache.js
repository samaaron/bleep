export default class BleepBufferCache {
  #loaded_buffers = new Map();
  #pending_fetches = new Map();

  constructor() {}

  async load_buffer(url, ctx) {
    if (this.#loaded_buffers.has(url)) {
      //console.log("Returning loaded buffer", url);
      // Return a resolved promise with the audio buffer if it's already loaded
      return Promise.resolve(this.#loaded_buffers.get(url));
    }

    if (this.#pending_fetches.has(url)) {
      //console.log("Returning pending fetch", url);
      // Return the pending fetch promise if the buffer is being fetched
      return this.#pending_fetches.get(url);
    }

    //console.log("Fetching audio buffer", url);
    // Create the fetch promise
    const fetchPromise = fetch(url)
      .then(response => response.arrayBuffer())
      .then(array_buffer => ctx.decodeAudioData(array_buffer))
      .then(audio_buffer => {
        // Store the loaded buffer and clean up the pending fetch
        this.#loaded_buffers.set(url, audio_buffer);
        this.#pending_fetches.delete(url);
        return audio_buffer;
      })
      .catch(error => {
        // Clean up the pending fetch on error
        this.#pending_fetches.delete(url);
        throw error;
      });

    // Store the pending fetch promise
    this.#pending_fetches.set(url, fetchPromise);
    return fetchPromise;
  }
}

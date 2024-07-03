export default class BleepAnalyser {
  #node;
  #analyser;
  #scope_data;
  #scope_buffer;
  #audio_context;

  constructor(ctx, node) {
    this.#audio_context = ctx;
    this.#node = node;

    this.#analyser = ctx.createAnalyser();
    this.#analyser.fftSize = 2048;

    this.#scope_data = new Uint8Array(this.#analyser.frequencyBinCount);
    this.#scope_buffer = ctx.createBuffer(
      1,
      this.#scope_data.length,
      ctx.sampleRate
    );

    this.#node.out.connect(this.#analyser);
  }

  getScopeData() {
    this.#analyser.getByteTimeDomainData(this.#scope_data);
    const data = this.#scope_buffer.getChannelData(0);

    // Copy the data from the Uint8Array to the AudioBuffer
    for (let i = 0; i < this.#scope_data.length; i++) {
      data[i] = (this.#scope_data[i] - 128) / 128;
    }
    return this.#scope_buffer;
  }
}

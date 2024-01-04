import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import { DEBUG_EFFECTS } from "./flags";

// ----------------------------------------------------------------
// Mapping from bleep reverb names to filenames
// ----------------------------------------------------------------

export const REVERB_FILENAME = {
  "reverb": "hall-medium.flac",
  "reverb_massive": "reactor-hall.flac",
  "reverb_large": "hall-large-church.flac",
  "reverb_medium": "hall-medium.flac",
  "reverb_small": "hall-small.flac",
  "room_large": "room-large.flac",
  "room_small": "room-small-bright.flac",
  "plate_drums": "plate-snare.flac",
  "plate_vocal": "rich-plate-vocal-2.flac",
  "plate_large": "plate-large.flac",
  "plate_small": "plate-small.flac",
  "ambience_large": "ambience-large.flac",
  "ambience_medium": "ambience-medium.flac",
  "ambience_small": "ambience-small.flac",
  "mic_reslo": "IR_ResloURA.flac",
  "mic_beyer": "IR_BeyerM500Stock.flac",
  "mic_foster": "IR_FosterDynamicDF1.flac",
  "mic_lomo": "IR_Lomo52A5M.flac"
}

// ----------------------------------------------------------------
// Reverb - convolutional reverb
// ----------------------------------------------------------------

export class Reverb extends BleepEffect {

  static REVERB_WET_LEVEL = 0.1

  _isValid;
  _convolver;

  /**
   * Creates an instance of Reverb.
   * @param {AudioContext} ctx - The audio context for the reverb effect.
   * @param {Monitor} monitor - The monitor object to track the reverb effect.
   */
  constructor(ctx, monitor) {
    super(ctx, monitor);
    this._isValid = false;
    this._convolver = new ConvolverNode(ctx);
    // connect everything up
    this._wetGain.connect(this._convolver);
    this._convolver.connect(this._out);
    this.setWetLevel(Reverb.REVERB_WET_LEVEL,ctx.currentTime);
  }

  /**
   * Loads an impulse response from a file for the reverb effect.
   * @param {string} filename - The filename of the impulse response.
   */
  async load(filename) {
    const impulseResponse = await this.getImpulseResponseFromFile(filename);
    if (this._isValid) {
      this._convolver.buffer = impulseResponse;
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
      this._isValid = true;
      return this._context.decodeAudioData(await reply.arrayBuffer());
    } catch (err) {
      this._isValid = false;
      if (DEBUG_EFFECTS)
        console.log(
          "unable to load the impulse response file called " + filename
        );
    }
  }

  /**
   * Calculates the time it takes for an input signal to fade out.
   * @returns {number} The duration of the impulse response, representing fade out time.
   */
  timeToFadeOut() {
    // the time an input to this reverb takes to fade out is equal to the duration
    // of the impulse response used
    return this._convolver.buffer.duration;
  }

  /**
   * Stops the reverb effect and cleans up resources.
   */
  stop() {
    super.stop();
    this._convolver.disconnect();
    this._convolver = null;
  }
}

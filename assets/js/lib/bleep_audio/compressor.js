import { BleepEffect } from "./effects";
import Monitor from "./monitor";
import Utility from "./utility";

/**
 * Compressor
 */
export class Compressor extends BleepEffect {

    _compressor

    constructor(ctx, monitor) {
        super(ctx, monitor);

        this._compressor = new DynamicsCompressorNode(ctx, {
            threshold : -50,
            knee : 40,
            ratio : 12,
            attack : 0,
            release : 0.25
        });
        this._compressor.connect(this._out);
    }

    setRatio(r, when) {
        this._compressor.ratio.setValueAtTime(r, when);
    }

    /**
     * Set the parameters of this effect
     * @param {object} params - key value list of parameters
     * @param {number} when - the time at which the change should occur
     */
    setParams(params, when) {
        super.setParams(params, when);
        if (typeof params.ratio !== "undefined") {
            this.setRatio(params.ratio, when);
        }
    }

    /**
     * Stop the effect and tidy up
     */
    stop() {
        super.stop();
        this._compressor.disconnect();
        this._compressor = null;
    }


}


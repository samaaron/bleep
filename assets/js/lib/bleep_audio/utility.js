class Utility {

    /**
     * Clamps a value between a minimum and a maximum.
     * @param {number} value - The value to clamp.
     * @param {number} min - The minimum value.
     * @param {number} max - The maximum value.
     * @returns {number} The clamped value.
     * @private
     */
    static clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    }

    /**
     * Converts a MIDI note number to its frequency in hertz.
     * 
     * @param {number} m - The MIDI note number.
     * @returns {number} The frequency in hertz for the given MIDI note.
     */
    static midiNoteToHz(m) {
        return 440 * Math.pow(2, (m - 69) / 12.0);
    }

}

export default Utility;
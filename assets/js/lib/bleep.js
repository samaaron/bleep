import BleepAudioCore from "./bleep_audio/core";
import BleepComms from "./bleep_comms";
import "./bleep_editor";

export default class Bleep {
  #user_id;
  #bleep_audio;
  #comms;

  constructor(user_id) {
    this.#user_id = user_id;
    this.#bleep_audio = new BleepAudioCore();
    this.#comms = new BleepComms(this.#user_id, this.#bleep_audio);
  }

  join_jam_session(jam_session_id) {
    this.#comms.join_jam_session(jam_session_id);
    return this.jam_sessions();
  }

  leave_jam_session(jam_session_id) {
    this.#comms.leave_jam_session(jam_session_id);
    return this.jam_sessions();
  }

  leave_all_jam_sessions() {
    this.#comms.leave_all_jam_sessions();
    return this.jam_sessions();
  }

  jam_sessions() {
    return this.#comms.jam_sessions();
  }

  idempotentInitAudio() {
    this.#bleep_audio.idempotentInitAudio();
  }

  idempotent_start_editor_session(editor_id) {
    this.idempotentInitAudio();
    const final_mix_fx_id = `${editor_id}-final-mix-fx`;
    this.#bleep_audio.idempotentStartFinalMix(final_mix_fx_id);
  }

  restart_editor_session(editor_id) {
    this.#bleep_audio.restartFinalMix(`${editor_id}-final-mix-fx`);
  }
}

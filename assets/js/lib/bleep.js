import BleepAudioCore from "./bleep_audio/core";
import BleepPrescheduler from "./bleep_prescheduler";
import BleepComms from "./bleep_comms";
import "./bleep_editor";

export default class Bleep {
  #user_id;
  #bleep_audio;
  #prescheduler;
  #comms

  constructor(user_id) {
    this.#user_id = user_id;
    this.#bleep_audio = new BleepAudioCore();
    this.#prescheduler = new BleepPrescheduler(this.#bleep_audio);
    this.#comms = new BleepComms(this.#user_id, this.#prescheduler);
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
}

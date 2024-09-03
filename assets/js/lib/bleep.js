import BleepAudioCore from "./bleep_audio_core";
import BleepPrescheduler from "./bleep_prescheduler";
import BleepComms from "./bleep_comms";
import "./bleep_monaco_editor_config";

export default class Bleep {
  #user_id;
  #bleep_audio;
  #prescheduler;
  #comms;

  #editors;

  constructor(user_id) {
    this.#user_id = user_id;
    this.#editors = {};
    this.#bleep_audio = new BleepAudioCore();
    this.#prescheduler = new BleepPrescheduler(this.#bleep_audio);
    this.#comms = new BleepComms(this.#user_id, this, this.#bleep_audio, this.#prescheduler);

  }

  set_volume(vol) {
    this.#bleep_audio.setVolume(vol);
  }
  clear_editors() {
    this.#editors = {};
  }

  add_editor(editor_id, editor) {
    this.#editors[editor_id] = editor;
  }

  editor_content(editor_id) {
    return this.#editors[editor_id].getCode();
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

  idempotentStartFinalMix(final_mix_fx_id) {
    return this.#bleep_audio.idempotentStartFinalMix(final_mix_fx_id);
  }

  stopFinalMix(final_mix_fx_id) {
    this.#bleep_audio.stopFinalMix(final_mix_fx_id);
  }

  createNodeAnalyser(audio_node) {
    return this.#bleep_audio.createNodeAnalyser(audio_node);
  }
}

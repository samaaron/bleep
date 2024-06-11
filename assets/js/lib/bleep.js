import BleepAudioCore from "./bleep_audio/core";
import { linearPath, polarPath } from "../../vendor/waveform-path.js";
import BleepComms from "./bleep_comms";
import "./bleep_editor";

export default class Bleep {
  #user_id;
  #bleep_audio;
  #comms;
  #editor_final_fxs;
  #editor_running_scope_loops;
  #editor_stopping_scope_loops;
  #editors;

  constructor(user_id) {
    this.#user_id = user_id;
    this.#editors = {};
    this.#bleep_audio = new BleepAudioCore();
    this.#comms = new BleepComms(this.#user_id, this.#bleep_audio);
    this.#editor_final_fxs = {};
    this.#editor_running_scope_loops = {};
    this.#editor_stopping_scope_loops = {};
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
    return this.#editors[editor_id].getValue();
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

  idempotent_start_editor_session(editor_id, scope_node) {
    this.idempotentInitAudio();
    const final_mix_fx_id = `${editor_id}-final-mix-fx`;
    const final_fx = this.#bleep_audio.idempotentStartFinalMix(final_mix_fx_id);
    if (final_fx !== null) {
      this.#editor_final_fxs[editor_id] = final_fx; // Store the latest final_fx
      if (!this.#editor_running_scope_loops[editor_id]) {
        this.start_scope(scope_node, editor_id);
      }
    }
  }

  restart_editor_session(editor_id) {
    this.#bleep_audio.restartFinalMix(`${editor_id}-final-mix-fx`);
    this.#editor_stopping_scope_loops[editor_id] = true;
    setTimeout(() => {
      if (this.#editor_stopping_scope_loops[editor_id]) {
        this.#editor_running_scope_loops[editor_id] = false;
      }
    }, 1000);
  }

  start_scope(scope_node, editor_id) {
    scope_node.style.strokeWidth = "2px";

    const options = {
      type: "bars",
      samples: 180,
      height: 50,
      top: 25,
      left: 25,
      width: 50,
      distance: 10,
      normalize: false,
      animationframes: 60,
      animation: true,
      paths: [
        {
          d: "A",
          sdeg: 0,
          sr: 5,
          edeg: 90,
          er: 20,
          rx: 4,
          ry: 4,
          angle: 180,
          arc: 1,
          sweep: 1,
        },
      ],
    };
    const update_waveform_path = () => {
      if (!this.#editor_running_scope_loops[editor_id]) return; // Stop the loop if it's been cleared
      const final_fx = this.#editor_final_fxs[editor_id]; // Get the latest final_fx
      const data = final_fx.getScopeData();
      const path = polarPath(data, options);
      scope_node.setAttribute("d", path);
      requestAnimationFrame(update_waveform_path);
    };

    this.#editor_running_scope_loops[editor_id] = true;
    this.#editor_stopping_scope_loops[editor_id] = false;
    update_waveform_path();
  }
}

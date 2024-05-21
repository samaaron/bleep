import BleepAudioCore from "./bleep_audio/core";
import { linearPath, polarPath } from "../../vendor/waveform-path.js";
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

  idempotent_start_editor_session(editor_id, scope_node) {
    this.idempotentInitAudio();
    const final_mix_fx_id = `${editor_id}-final-mix-fx`;
    const final_fx = this.#bleep_audio.idempotentStartFinalMix(final_mix_fx_id);
    if (final_fx !== null) {
      this.start_scope(scope_node, final_fx);
    }
  }

  restart_editor_session(editor_id) {
    this.#bleep_audio.restartFinalMix(`${editor_id}-final-mix-fx`);
  }

  start_scope(scope_node, final_fx) {
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
          sr: 13,
          edeg: 100,
          er: 13,
          rx: 5,
          ry: 5,
          angle: 100,
          arc: 1,
          sweep: 1,
        },
      ],
    };
    this.updateWaveformPath(scope_node, final_fx, options);
  }

  updateWaveformPath(scope_node, final_fx, options) {
    const data = final_fx.getScopeData();
    const path = polarPath(data, options);
    scope_node.setAttribute("d", path);

    requestAnimationFrame(() =>
      this.updateWaveformPath(scope_node, final_fx, options)
    );
  }
}

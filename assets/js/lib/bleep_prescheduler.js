// Bleep prescheduler

export default class BleepPrescheduler {
  #bleep_audio;
  #worker;

  constructor(bleepAudio) {
    this.#bleep_audio = bleepAudio;
    this.#worker = new Worker("/assets/bleep_prescheduler.worker.js");

    this.#worker.onmessage = (e) => {
      const data = e.data;
      switch (data.action) {
        case "timedDispatch":
          this.#bleep_audio.jsonDispatch(data.adjustedTimeS, data.msg);
          break;
        case "consoleLog":
          console.log(data.logMsg);
          break;
      }
    };

    this.#start_gc();
  }

  schedule(userId, editorId, runId, runTag, timeS, timeDeltaS, msg) {
    this.#pre_schedule(msg);
    this.#worker.postMessage({
      action: "schedule",
      userId,
      editorId,
      runId,
      runTag,
      timeS,
      timeDeltaS,
      msg,
    });
  }

  cancel_editor_tag(editorId, runTag) {
    this.#worker.postMessage({
      action: "cancelEditorTag",
      editorId,
      runTag,
    });
  }

  cancel_editor(editorId) {
    this.#worker.postMessage({
      action: "cancelEditor",
      editorId,
    });
  }

  cancel_all_tags() {
    this.#worker.postMessage({
      action: "cancelEditor",
    });
  }

  reset_time_deltas() {
    this.#worker.postMessage({
      action: "cancelEditor",
    });
  }

  #start_gc() {
    setInterval(() => {
      this.#worker.postMessage({action: "gc"});
    }, 5000);
  }

  #pre_schedule(msg) {
    // Called before a message is scheduled
    //console.log("Pre dispatch: ", msg);

    if (msg.cmd === "triggerSample" || msg.cmd === "triggerGrains") {
      this.#bleep_audio.loadSample(msg.sample_name);
    }

    if (msg.cmd === "triggerFX") {
      this.#bleep_audio.preloadFX(msg.fx_name);
    }
  }
}

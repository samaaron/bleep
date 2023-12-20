import * as monaco from "../../vendor/monaco-editor/esm/vs/editor/editor.main";

self.MonacoEnvironment = {
  getWorkerUrl: function (moduleId, label) {
    return "assets/monaco-editor/editor.worker.js";
  },
};

const BleepEditor = {
  mounted() {
    const { path, language, content, runButtonId, cueButtonId } =
      this.el.dataset;
    const run_button = this.el.querySelector("#" + this.el.dataset.runButtonId);
    const cue_button = this.el.querySelector("#" + this.el.dataset.cueButtonId);
    const container = this.el.querySelector("[monaco-code-editor]");

    this.editor = monaco.editor.create(container, {
      theme: "vs-dark",
      value: content,
      language: language,
      minimap: {
        enabled: false,
      },
    });

    run_button.addEventListener("click", (e) => {
      window.bleep.idempotentInit();
      this.pushEvent("eval-code", {
        value: this.editor.getValue(),
        path: path,
      });
      console.log(this.editor.getValue());
    });

    cue_button.addEventListener("click", (e) => {
      window.bleep.idempotentInit();
      this.pushEvent("cue-code", {
        value: this.editor.getValue(),
        path: path,
      });
      console.log(this.editor.getValue());
    });
  },

  destroyed() {
    if (this.editor) this.editor.dispose();
  },
};

export default BleepEditor;

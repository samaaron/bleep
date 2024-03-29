import * as monaco from "../../../vendor/monaco-editor/esm/vs/editor/editor.main";

const BleepEditorHook = {
  mounted() {
    const path = this.el.dataset.path;
    const language = this.el.dataset.language;
    const content = this.el.dataset.content;
    const run_button_id = this.el.dataset.runButtonId;
    const cue_button_id = this.el.dataset.cueButtonId;
    const stop_button_id = this.el.dataset.stopButtonId;
    const editor_id = this.el.dataset.editorId;
    const result_id = this.el.dataset.resultId;
    const run_button = this.el.querySelector("#" + run_button_id);
    const cue_button = this.el.querySelector("#" + cue_button_id);
    const stop_button = this.el.querySelector("#" + stop_button_id);
    const container = this.el.querySelector("[monaco-code-editor]");
    this.editor = monaco.editor.create(container, {
      theme: "bleep-dark",
      value: content,
      language: language,
      matchBrackets: true,
      bracketPairColorization: { enabled: true },
      scrollbar: { vertical: "hidden" },
      autoHeight: true,
      minimap: {
        enabled: false,
      },
      scrollBeyondLastLine: false,
    });
    2;

    this.editor.getDomNode().addEventListener(
      "wheel",
      function (e) {
        0 - window.scrollBy(0, e.deltaYy);
      },
      { passive: false }
    );

    function autoResizeMonacoEditor(mon) {
      const lineHeight = mon.getOption(monaco.editor.EditorOption.lineHeight);
      const lineCount = mon.getModel().getLineCount();
      const contentHeight = lineHeight * lineCount;

      mon.layout({
        width: container.clientWidth,
        height: contentHeight,
      });
    }

    this.editor.onDidChangeModelContent(() => {
      autoResizeMonacoEditor(this.editor);
    });

    run_button.addEventListener("click", (e) => {
      window.bleep.idempotentInitAudio();
      const code = this.editor.getValue();
      const placeholder = "bleep_tmp_placeholder()";
      const formatted = luamin
        .Beautify(`${code}\n${placeholder}`, {
          RenameVariables: false,
          RenameGlobals: false,
          SolveMath: false,
        })
        .slice(0, -(placeholder.length + 1));

      this.editor.setValue(formatted);

      this.pushEvent("run-code", {
        code: formatted,
        path: path,
        result_id: result_id,
        editor_id: editor_id,
      });

      console.log(this.editor.getValue());
    });

    cue_button.addEventListener("click", (e) => {
      window.bleep.idempotentInitAudio();
      const code = this.editor.getValue();
      const placeholder = "bleep_tmp_placeholder()";
      const formatted = luamin
        .Beautify(`${code}\n${placeholder}`, {
          RenameVariables: false,
          RenameGlobals: false,
          SolveMath: false,
        })
        .slice(0, -(placeholder.length + 1));

      this.editor.setValue(formatted);

      this.pushEvent("cue-code", {
        code: formatted,
        path: path,
        result_id: result_id,
        editor_id: editor_id,
      });

      console.log(this.editor.getValue());
    });

    stop_button.addEventListener("click", (e) => {
      this.pushEvent("stop-editor-runs", {
        editor_id: editor_id,
      });
    });

    autoResizeMonacoEditor(this.editor);
  },

  destroyed() {
    if (this.editor) this.editor.dispose();
  },
};

export default BleepEditorHook;

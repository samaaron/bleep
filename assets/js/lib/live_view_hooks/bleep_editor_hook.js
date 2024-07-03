import BleepEditor from "../bleep_editor";

const BleepEditorHook = {
  mounted() {
    const path = this.el.dataset.path;
    const language = this.el.dataset.language;
    const run_button_id = this.el.dataset.runButtonId;
    const cue_button_id = this.el.dataset.cueButtonId;
    const stop_button_id = this.el.dataset.stopButtonId;
    const editor_id = this.el.dataset.editorId;
    const result_id = this.el.dataset.resultId;
    const scope_id = this.el.dataset.scopeId;
    const run_button = this.el.querySelector(`#${run_button_id}`);
    const cue_button = this.el.querySelector(`#${cue_button_id}`);
    const stop_button = this.el.querySelector(`#${stop_button_id}`);
    const container = this.el.querySelector("[monaco-code-editor]");
    const scope = this.el.querySelector(`#${scope_id}`);

    const code = sessionStorage.getItem(editor_id) ?? this.el.dataset.content;

    this.editor = new BleepEditor(bleep, code, language, editor_id, container, scope);
    const evalCode = (strategy) => {
      this.editor.idempotent_start_editor_session(editor_id, scope).then(() => {
        const code = this.editor.getCode();

        if (code.length > 20 * 1024) {
          alert("Error - code is too large to run.");
          return;
        }

        sessionStorage.setItem(editor_id, code);
        const placeholder = "bleep_tmp_placeholder()";
        let formatted;
        try {
          formatted = luamin
            .Beautify(`${code}\n${placeholder}`, {
              RenameVariables: false,
              RenameGlobals: false,
              SolveMath: false,
            })
            .slice(0, -(placeholder.length + 1));

          this.editor.setCode(formatted);
          this.pushEvent(strategy, {
            code: formatted,
            path: path,
            result_id: result_id,
            editor_id: editor_id,
          });
        } catch (error) {
          formatted = code;
          const error_msg = "Syntax Error<br/>" + error;
          document.getElementById(result_id).innerHTML = error_msg;
        }
      });
    };

    run_button.addEventListener("click", (e) => {
      evalCode("run-code");
    });

    cue_button.addEventListener("click", (e) => {
      evalCode("cue-code");
    });

    stop_button.addEventListener("click", (e) => {
      this.pushEvent("stop-editor-runs", {
        editor_id: editor_id,
      });
      this.editor.stop_editor_session();
    });

    window.bleep.add_editor(editor_id, this.editor);
  },

  destroyed() {
    if (this.editor) this.editor.dispose();
  },
};

export default BleepEditorHook;

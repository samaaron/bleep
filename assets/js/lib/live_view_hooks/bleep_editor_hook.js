import BleepEditor from "../bleep_editor";

const BleepEditorHook = {
  mounted() {
    const path = this.el.dataset.path;
    const language = this.el.dataset.language;
    const run_button_id = this.el.dataset.runButtonId;
    const cue_button_id = this.el.dataset.cueButtonId;
    const stop_button_id = this.el.dataset.stopButtonId;
    const loop_button_id = this.el.dataset.loopButtonId;
    const editor_id = this.el.dataset.editorId;
    const result_id = this.el.dataset.resultId;
    const scope_id = this.el.dataset.scopeId;
    const run_buttons = document.querySelectorAll(`.${run_button_id}`);
    const cue_buttons = document.querySelectorAll(`.${cue_button_id}`);
    const stop_buttons = document.querySelectorAll(`.${stop_button_id}`);
    const loop_buttons = document.querySelectorAll(`.${loop_button_id}`);
    const container = this.el.querySelector("[monaco-code-editor]");
    const scopes = document.querySelectorAll(`.${scope_id}`);

    const code = sessionStorage.getItem(editor_id) ?? this.el.dataset.content;

    this.editor = new BleepEditor(
      bleep,
      code,
      language,
      editor_id,
      container,
      scopes
    );

    window.addEventListener(`phx:run-editor-with-id`, (e) => {
      if (e.detail.editor_id === editor_id) {
        evalCode("run-code", e.detail.start_time_s);
      }
    });

    const evalCode = (strategy, start_time_s = null) => {
      this.editor.idempotent_start_editor_session().then(() => {
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
            start_time_s: start_time_s,
          });
        } catch (error) {
          formatted = code;
          const error_msg = "Syntax Error<br/>" + error;
          document.getElementById(result_id).innerHTML = error_msg;
        }
      });
    };

    run_buttons.forEach((run_button) => {
      run_button.addEventListener("click", (e) => {
        evalCode("run-code");
      });
    });

    cue_buttons.forEach((cue_button) => {
      cue_button.addEventListener("click", (e) => {
        evalCode("cue-code");
      });
    });

    loop_buttons.forEach((loop_button) => {
      loop_button.addEventListener("click", (e) => {
        this.pushEvent("toggle-loop-cue", {
          editor_id: editor_id,
        });
      });
    });

    stop_buttons.forEach((stop_button) => {
      stop_button.addEventListener("click", (e) => {
        this.pushEvent("stop-editor-runs-and-cues", {
          editor_id: editor_id,
        });
        this.editor.stop_editor_session();
      });
    });

    window.bleep.add_editor(editor_id, this.editor);
  },

  destroyed() {
    if (this.editor) this.editor.dispose();
  },
};

export default BleepEditorHook;

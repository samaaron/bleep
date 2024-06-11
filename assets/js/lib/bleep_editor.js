import { linearPath, polarPath } from "../../vendor/waveform-path.js";
import * as monaco from "../../vendor/monaco-editor/esm/vs/editor/editor.main";
export default class BleepEditor {
  #id;
  #monaco_editor;
  #log;
  #final_fxs;
  #running_scope_loops;
  #stopping_scope_loops;
  #bleep;

  constructor(bleep, code, language, id, monaco_container) {
    this.#bleep = bleep;
    this.#final_fxs = {};
    this.#running_scope_loops = {};
    this.#stopping_scope_loops = {};
    this.#monaco_editor = this.#init_monaco_editor(
      monaco_container,
      language,
      code
    );
  }

  getCode() {
    return this.#monaco_editor.getValue();
  }

  setCode(code) {
    this.#monaco_editor.setValue(code);
  }

  restart_editor_session(editor_id) {
    this.#bleep.restartFinalMix(`${editor_id}-final-mix-fx`);
    this.#stopping_scope_loops[editor_id] = true;
    setTimeout(() => {
      if (this.#stopping_scope_loops[editor_id]) {
        this.#running_scope_loops[editor_id] = false;
      }
    }, 1000);
  }

  idempotent_start_editor_session(editor_id, scope_node) {
    this.#bleep.idempotentInitAudio();
    const final_mix_fx_id = `${editor_id}-final-mix-fx`;
    const final_fx = this.#bleep.idempotentStartFinalMix(final_mix_fx_id);
    if (final_fx !== null) {
      this.#final_fxs[editor_id] = final_fx; // Store the latest final_fx
      if (!this.#running_scope_loops[editor_id]) {
        this.start_scope(scope_node, editor_id);
      }
    }
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
      if (!this.#running_scope_loops[editor_id]) return; // Stop the loop if it's been cleared
      const final_fx = this.#final_fxs[editor_id]; // Get the latest final_fx
      const data = final_fx.getScopeData();
      const path = polarPath(data, options);
      scope_node.setAttribute("d", path);
      requestAnimationFrame(update_waveform_path);
    };

    this.#running_scope_loops[editor_id] = true;
    this.#stopping_scope_loops[editor_id] = false;
    update_waveform_path();
  }

  dispose() {
    this.#monaco_editor.dispose();
  }

  #init_monaco_editor(monaco_container, language, code) {
    const monaco_editor = monaco.editor.create(monaco_container, {
      theme: "bleep-dark",
      value: code,
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

    monaco_editor.getDomNode().addEventListener(
      "wheel",
      function (e) {
        0 - window.scrollBy(0, e.deltaYy);
      },
      { passive: false }
    );

    monaco_editor.onDidChangeModelContent(() => {
      autoResizeMonacoEditor(monaco_editor);
    });

    const autoResizeMonacoEditor = (mon) => {
      const lineHeight = mon.getOption(monaco.editor.EditorOption.lineHeight);
      const lineCount = mon.getModel().getLineCount();
      const contentHeight = lineHeight * lineCount;

      mon.layout({
        width: monaco_container.clientWidth,
        height: contentHeight,
      });
    };

    autoResizeMonacoEditor(monaco_editor);
    return monaco_editor;
  }
}

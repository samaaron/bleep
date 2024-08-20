import { linearPath, polarPath } from "../../vendor/waveform-path.js";
import * as monaco from "../../vendor/monaco-editor/esm/vs/editor/editor.main";

export default class BleepEditor {
  #bleep;
  #id;
  #monaco_editor;
  #log;
  #running_scope_loop;
  #stopping_scope_loop;
  #scope_nodes;
  #scope_analyser;
  #scope_options;
  #final_mix_fx;
  #final_mix_fx_id;

  constructor(bleep, code, language, id, monaco_container, scope_nodes) {
    this.#bleep = bleep;
    this.#id = id;
    this.#monaco_editor = this.#init_monaco_editor(
      monaco_container,
      language,
      code
    );
    this.#scope_options = {
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
    this.#running_scope_loop = null;
    this.#scope_nodes = scope_nodes;
    this.#scope_analyser = null;
    this.#final_mix_fx = null;
    this.#final_mix_fx_id = `${id}-final-mix-fx`;

  }

  getCode() {
    return this.#monaco_editor.getValue();
  }

  setCode(code) {
    this.#monaco_editor.setValue(code);
  }

  stop_editor_session() {
    this.#bleep.stopFinalMix(this.#final_mix_fx_id);
    this.#stopping_scope_loop = true;
    setTimeout(() => {
      if (this.#stopping_scope_loop) {
        this.#running_scope_loop = false;
      }
    }, 1000);
  }

  async idempotent_start_editor_session() {
    await this.#bleep.idempotentInitAudio();
    const final_mix_fx = this.#bleep.idempotentStartFinalMix(
      this.#final_mix_fx_id
    );
    if (final_mix_fx !== null) {
      this.#scope_analyser = this.#bleep.createNodeAnalyser(final_mix_fx);
      this.#final_mix_fx = final_mix_fx;

      this.start_scopes();
    }
  }



  start_scopes() {

    this.#scope_nodes.forEach((scope_node) => {
      scope_node.style.strokeWidth = "2px";
    });


    const run_scope_animation = () => {
      if (!this.#running_scope_loop) return; // Stop the loop if it's been cleared
      this.#update_waveform_path();
      requestAnimationFrame(run_scope_animation);
    };

    this.#running_scope_loop = true;
    this.#stopping_scope_loop = false;
    run_scope_animation();
  }

  dispose() {
    this.stop_editor_session();
    this.#running_scope_loop = false;
    this.#monaco_editor.dispose();
  }

  #update_waveform_path() {
    const data = this.#scope_analyser.getScopeData();
    const path = polarPath(data, this.#scope_options);

    this.#scope_nodes.forEach((scope_node) => {
      scope_node.setAttribute("d", path);

      const viewBox = scope_node.ownerSVGElement.getAttribute("viewBox");
      if (viewBox) {
        const [minX, minY, width, height] = viewBox.split(" ").map(Number);

        const bbox = scope_node.getBBox();

        const scaleX = width / bbox.width;
        const scaleY = height / bbox.height;
        const scale = Math.min(scaleX, scaleY) * 0.8;

        const translateX = (width - bbox.width * scale) / 2 - bbox.x * scale;
        const translateY = (height - bbox.height * scale) / 2 - bbox.y * scale;

        scope_node.setAttribute(
          "transform",
          `translate(${translateX}, ${translateY}) scale(${scale})`
        );
      }
    });
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

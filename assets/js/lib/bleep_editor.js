import * as monaco from "../../vendor/monaco-editor/esm/vs/editor/editor.main";

self.MonacoEnvironment = {
  getWorkerUrl: function (moduleId, label) {
    return "assets/monaco-editor/editor.worker.js";
  },
};

monaco.editor.defineTheme("bleep-dark", {
  base: "vs-dark",
  inherit: true,
  rules: [
    { token: "", foreground: "#ededed" },
    { token: "keyword", foreground: "#939bA2" },
    { token: "comment", foreground: "#808080" },
    { token: "number", foreground: "#82AAFF" },
    { token: "string", foreground: "#61CE3C" },
    { token: "keyword", foreground: "#ff1493" },
    { token: "identifier", foreground: "#d3ded3" },
  ],
  colors: {
    "editor.background": "#000000", // RGBA for transparency
    "editor.selectionBackground": "#FF8C0090",
    "editorBracketMatch.background": "#FF8C0050",
    "editorBracketMatch.border": "#FF8C0050",
    "editorLineNumber.foreground": "#808080",
    "editorBracketHighlight.foreground1": "#808080",
    "editorBracketHighlight.foreground2": "#707070",
    "editorBracketHighlight.foreground3": "#808080",
  },
});

const BleepEditor = {
  mounted() {
    const { path, language, content, runButtonId, cueButtonId } =
      this.el.dataset;
    const run_button = this.el.querySelector("#" + this.el.dataset.runButtonId);
    const cue_button = this.el.querySelector("#" + this.el.dataset.cueButtonId);
    const result_id = this.el.dataset.resultId;
    const uuid = this.el.dataset.uuid;
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

    this.editor.getDomNode().addEventListener(
      "wheel",
      function (e) {
        window.scrollBy(0, e.deltaY);
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
      window.bleep.idempotentInit();
      const code = this.editor.getValue();
      const formatted = luamin.Beautify(code, {
        RenameVariables: false,
        RenameGlobals: false,
        SolveMath: false,
      });

      this.editor.setValue(formatted);
      this.pushEvent("eval-code", {
        value: formatted,
        path: path,
        uuid: uuid,
        result_id: result_id,
      });
      console.log(this.editor.getValue());
    });

    cue_button.addEventListener("click", (e) => {
      window.bleep.idempotentInit();
      this.pushEvent("cue-code", {
        value: this.editor.getValue(),
        path: path,
        uuid: uuid,
        result_id: result_id,
      });
      console.log(this.editor.getValue());
    });

    autoResizeMonacoEditor(this.editor);
  },

  destroyed() {
    if (this.editor) this.editor.dispose();
  },
};

export default BleepEditor;

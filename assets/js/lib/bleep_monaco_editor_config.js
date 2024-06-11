import * as monaco from "../../vendor/monaco-editor/esm/vs/editor/editor.main";

self.MonacoEnvironment = {
  getWorkerUrl: function (moduleId, label) {
    return "/assets/monaco-editor/editor.worker.js";
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



const BleepSaveHook = {
  mounted() {
    this.handleEvent("save_content", ({ content }) => {
      const content_lua = jsonToLua(content);
      const link = document.createElement("a");
      const blob = new Blob([content_lua], { type: "text/plain" });
      link.href = URL.createObjectURL(blob);
      const formatted_date = new Date()
        .toISOString()
        .slice(0, 19)
        .replace(/[:T]/g, "-");
      link.download = `bleep-save-${formatted_date}.lua`;
      link.click();
    });
  },
};

function isBlank(str) {
  return /^\s*$/.test(str);
}

function jsonToLua(json) {
  let lua = "-- Bleep Save\n\n";
  lua += `title = "${json.title}"\n`;
  lua += `author = "${json.author}"\n`;
  lua += `user_id = "${json.user_id}"\n`;
  lua += `description = "${json.description}"\n`;
  lua += `bpm = ${json.bpm}\n`;
  lua += `quantum = ${json.quantum}\n`;
  lua += `\n`;
  if (isBlank(json.init)) {
    lua += `init = [[\n-- this code is automatically\n-- inserted before every run\n]]`;
  } else {
    lua += `init = [[\n${json.init}]]`;
  }

  lua += `\n\n`;
  lua += `content = {\n${jsonFragsToLua(json.frags)}\n} -- end content\n`;
  return lua;
}

function jsonFragsToLua(frags) {
  let lua = "";
  frags.forEach((frag) => {
    lua += `\n`;
    if (frag.kind == "editor") {
      const editor_content = window.bleep.editor_content(frag.frag_id);
      if (isBlank(editor_content)) {
        lua += `editor [[ ]],\n\n`;
      } else {
        lua += `editor [[\n`;
        lua += `${editor_content}`;
        lua += `]],\n\n`;
      }
    } else if (frag.kind == "markdown") {
      lua += `markdown [[\n`;
      lua += `${frag.content.trim()}\n`;
      lua += `]],\n\n`;
    }
  });

  return lua;
}

export default BleepSaveHook;

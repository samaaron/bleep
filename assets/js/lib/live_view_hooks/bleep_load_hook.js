const BleepLoadHook = {
  mounted() {
    document
      .getElementById("bleep-load-input")
      .addEventListener("change", (event) => {
        const file = event.target.files[0];
        if (file) {
          const max_size = 50 * 1024;
          if (file.size > max_size) {
            alert("Error - file is too large to load.");
            event.preventDefault();
            return;
          }
          const reader = new FileReader();
          reader.onload = (e) => {
            const content = e.target.result;
            if (validateContent(content)) {
              window.bleep.clear_editors();
              this.pushEvent("load", { content: content });
            }
          };
          reader.readAsText(file);
        } else {
          alert("Please select a valid bleep load file.");
        }
      });
  },
};

function validateContent(content) {
  try {
    luamin.Beautify(content, {
      RenameVariables: false,
      RenameGlobals: false,
      SolveMath: false,
    });
  } catch (error) {
    alert(`Syntax Error in load file:\n ${error}`);
    return false;
  }
  return true;
}

export default BleepLoadHook;

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// Vendored libs
import topbar from "../vendor/topbar";
import mermaid from "../vendor/mermaid";
import luamin from "../vendor/luamin";
window.luamin = luamin;

// Internal libs
import BleepEditor from "./lib/bleep_editor";
import BleepAudioCore from "./lib/bleep_audio/core";

mermaid.initialize({ startOnLoad: true });

let bleep = new BleepAudioCore();
window.bleep = bleep;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = { BleepEditor };
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

const bleep_init_button = document.getElementById("bleep-init-button");
const bleep_init_modal = document.getElementById("bleep-init-modal");

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

window.addEventListener(`phx:update-luareplres`, (e) => {
  document.getElementById(e.detail.result_id).innerHTML =
    e.detail.lua_repl_result;
});

window.addEventListener(`phx:bleep-audio`, (e) => {
  try {
    const msg = JSON.parse(e.detail.msg);
    //console.log(`got incoming msg: ${JSON.stringify(msg)}`)
    bleep.jsonDispatch(msg);
  } catch (ex) {
    console.log(`Incoming bleep-audio event error ${ex.message}`);
    console.log(ex);
  }
});

function bleep_modal_keydown(e) {
  if (
    e.key === "Enter" ||
    e.code === "Enter" ||
    e.key === " " ||
    e.code === "Space"
  ) {
    // Your code to handle the Enter key press goes here
    bleep_modal_clicked(e);
    console.log("Enter key pressed");
  }
}

function bleep_modal_clicked(e) {
  document.removeEventListener("keydown", bleep_modal_keydown);
  bleep_init_button.removeEventListener("click", bleep_modal_clicked);
  bleep_init_modal.removeEventListener("click", bleep_modal_clicked);

  bleep_init_modal.classList.add(
    "transition",
    "ease-out",
    "duration-1000",
    "opacity-100"
  );

  bleep.idempotentInit();
  bleep_init_modal.classList.remove("opacity-100");
  bleep_init_modal.classList.add("opacity-0");

  setTimeout(() => {
    bleep_init_modal.style.display = "none";
  }, 1000);
}

bleep_init_button.addEventListener("click", bleep_modal_clicked);
bleep_init_modal.addEventListener("click", bleep_modal_clicked);

document.addEventListener("keydown", bleep_modal_keydown);

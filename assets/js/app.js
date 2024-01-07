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
import BleepTime from "./lib/bleep_time";

mermaid.initialize({ startOnLoad: true });

let bleep = new BleepAudioCore();
window.bleep = bleep;

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = { BleepEditor, BleepTime };
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

window.addEventListener(`phx:bleep-time-ack`, (e) => {
  const now = Date.now() / 1000;
  const roundtrip_time1 = e.detail.roundtrip_time;
  const server_time = e.detail.server_time;
  const roundtrip_time2 = now;
  const single_way_time = (roundtrip_time2 - roundtrip_time1) / 2;
  window.bleep_time_delta = server_time - (now - single_way_time);
  console.log("Bleep time:")
  console.log(`T1 ${roundtrip_time1}s`);
  console.log(`S1 ${server_time}s`);
  console.log(`T2 ${roundtrip_time2}s`);
  console.log(`RT  ${(roundtrip_time2 - roundtrip_time1) * 1000 }ms`);
});

window.addEventListener(`phx:sched-bleep-audio`, (e) => {
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


let bleep_logo_hue_rotation = 0;
const bleep_logo = document.getElementById('bleep-logo');

function bleep_animate_logo() {
  // Increase the hue rotation angle
  bleep_logo_hue_rotation += 15;

  // Apply the hue rotation to the image
  bleep_logo.style.filter = `hue-rotate(${bleep_logo_hue_rotation}deg)`;

  // If the hue rotation angle is less than 360, keep animating
  if (bleep_logo_hue_rotation > 360) {
    bleep_logo_hue_rotation = 0;
  }

  setTimeout(() => {
      requestAnimationFrame(bleep_animate_logo);
    }, 400);
}

// Start the animation
bleep_animate_logo();
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
// import mermaid from "../vendor/mermaid";
import topbar from "../vendor/topbar";
import luamin from "../vendor/luamin";
window.luamin = luamin;

// Internal libs
import BleepEditor from "./lib/bleep_editor";
import BleepAudioCore from "./lib/bleep_audio/core";
import BleepTime from "./lib/bleep_time";
import BleepPrescheduler from "./lib/bleep_prescheduler";
import "./lib/bleep_modal";

// mermaid.initialize({ startOnLoad: true });

let bleep = new BleepAudioCore();
window.bleep = bleep;

let prescheduler = new BleepPrescheduler(bleep);

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = { BleepEditor, BleepTime };
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

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
  const roundtrip_time1 = e.detail.roundtrip_time;
  const server_time = e.detail.server_time;
  const roundtrip_time2 = Date.now() / 1000;
  const single_way_time = (roundtrip_time2 - roundtrip_time1) / 2;

  window.bleep_time_info = {
    delta: roundtrip_time2 - e.detail.latency_est - server_time,
    latency: e.detail.latency_est,
    latency_measurement: single_way_time,
  };
});

window.addEventListener(`phx:sched-bleep-audio`, (e) => {
  try {
    const msg = JSON.parse(e.detail.msg);
    const time = e.detail.time_s;
    const run_id = e.detail.run_id;
    const tag = e.detail.tag;
    prescheduler.schedule(time, tag, msg, window.bleep_time_info.delta);
  } catch (ex) {
    console.log(`Incoming bleep-audio event error ${ex.message}`);
    console.log(ex);
  }
});
let bleep_logo_hue_rotation = 0;
const bleep_logo = document.getElementById("bleep-logo");

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

import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

import { v4 as uuidv4 } from "../vendor/uuid/index";
import topbar from "../vendor/topbar";
import luamin from "../vendor/luamin";
window.luamin = luamin;

import BleepEditorHook from "./lib/live_view_hooks/bleep_editor_hook";
import BleepSaveHook from "./lib/live_view_hooks/bleep_save_hook";
import BleepLoadHook from "./lib/live_view_hooks/bleep_load_hook";
import Bleep from "./lib/bleep";
import BleepModal from "./lib/bleep_modal";

const bleep_user_id = get_or_create_user_uuid();

window.bleep = new Bleep(bleep_user_id);
window.bleep_modal = new BleepModal(window.bleep)
window.bleep.join_jam_session(bleep_user_id);

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { BleepEditorHook, BleepSaveHook, BleepLoadHook },
  params: { _csrf_token: csrfToken, bleep_user_id: bleep_user_id },
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
window.luamin = luamin;

window.addEventListener(`phx:update-luareplres`, (e) => {
  document.getElementById(e.detail.result_id).innerHTML =
    e.detail.lua_repl_result;
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

function get_or_create_user_uuid() {
  let user_uuid = sessionStorage.getItem("bleep_user_uuid");
  if (!user_uuid) {
    user_uuid = uuidv4();
    sessionStorage.setItem("bleep_user_uuid", user_uuid);
  }
  return user_uuid;
}

function init_main_volume_slider() {
  const slider = document.getElementById("bleep-main-volume-slider");

  const updateSliderBackground = (value) => {
    slider.style.setProperty("--slider-value", `${value * 50}%`);
  };

  slider.addEventListener("input", (event) => {
    const value = event.target.value;
    updateSliderBackground(value);
    window.bleep.set_volume(value);
    console.log("Volume set to: ", value);
  });

  updateSliderBackground(slider.value);
}

document.addEventListener("DOMContentLoaded", function () {
  init_main_volume_slider();
  bleep_animate_logo();
});

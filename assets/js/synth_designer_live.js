import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

import { v4 as uuidv4 } from "../vendor/uuid/index";
import topbar from "../vendor/topbar";

const bleep_user_id = get_or_create_user_uuid();

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {},
  params: { _csrf_token: csrfToken, bleep_user_id: bleep_user_id },
});

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

function get_or_create_user_uuid() {
  let user_uuid = sessionStorage.getItem("bleep_user_uuid");
  if (!user_uuid) {
    user_uuid = uuidv4();
    sessionStorage.setItem("bleep_user_uuid", user_uuid);
  }
  return user_uuid;
}

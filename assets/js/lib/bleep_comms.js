import BleepPrescheduler from "./bleep_prescheduler";
import { Socket } from "phoenix";
import RingBuffer from "../../vendor/ringbuffer";

export default class BleepComms {
  #user_id;
  #prescheduler;
  #bleep_socket;
  #jam_session_channels;
  #time_sync_channel;
  #server_time_info;
  #bleep_core;

  constructor(user_id, bleep_core, prescheduler) {
    this.#user_id = user_id;
    this.#bleep_core = bleep_core;
    this.#prescheduler = prescheduler;
    this.#bleep_socket = new Socket("/bleep-socket", {
      params: { user_id: user_id },
    });
    this.#bleep_socket.connect();
    this.#jam_session_channels = {};
    this.#time_sync_channel = this.#join_time_sync_channel(
      this.#bleep_socket,
      this.#user_id
    );

    this.#server_time_info = {
      ping_s: 0,
      delta_s: 0,
      ping_times: new RingBuffer(20),
    };
    this.#start_server_time_info_updater();
  }

  join_jam_session(jam_session_id) {
    if (this.#jam_session_channels[jam_session_id]) {
    } else {
      let channel = this.#bleep_socket.channel(
        `bleep-audio:${jam_session_id}`,
        {}
      );

      channel.on("sched-bleep-audio", (payload) => {
        this.#handle_server_event_sched_bleep_audio(payload);
      });

      channel.on("stop-editor-runs", (payload) => {
        this.#prescheduler.cancel_tag(payload.editor_id);
      });

      channel.on("stop-all-runs", (_payload) => {
        this.#prescheduler.cancel_all_tags();
        this.#bleep_core.restartMainOut();
      });

      channel
        .join()
        .receive("ok", (resp) => {})
        .receive("error", (resp) => {
          console.log(
            `Unable to join bleep channel [${jam_session_id}].`,
            resp
          );
        });

      this.#jam_session_channels[jam_session_id] = channel;
    }
  }

  leave_jam_session(jam_session_id) {
    if (this.#jam_session_channels[jam_session_id]) {
      this.#jam_session_channels[jam_session_id].leave();
      delete this.#jam_session_channels[jam_session_id];
    }
  }

  jam_sessions() {
    return Object.keys(this.#jam_session_channels);
  }

  #join_time_sync_channel(socket, user_id) {
    let channel = socket.channel(`bleep-time-sync:${user_id}`, {});

    channel
      .join()
      .receive("ok", (resp) => {})
      .receive("error", (resp) => {
        console.log(`Unable to join time sync channel.`, resp);
      });

    return channel;
  }

  #start_server_time_info_updater() {
    // prepopluate time info
    [
      1.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.5, 8.0, 8.5, 9.0, 9.5, 10.5, 11.0,
      11.5, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5,
    ].forEach((i) => {
      setTimeout(() => {
        this.#bleep_server_ping();
      }, i * 1000);
    });

    // then update every 10s
    setTimeout(() => {
      setInterval(() => {
        this.#bleep_server_ping();
      }, 10000);
    }, 15000);
  }

  #average_ping_time() {
    const ping_count = this.#server_time_info.ping_times.size();
    const pings = this.#server_time_info.ping_times.peekN(ping_count);

    if (pings.length <= 4) {
      // If we have 4 or fewer pings, return the average of all pings
      const sum = pings.reduce((a, b) => a + b, 0);
      return sum / pings.length;
    }

    const mean = pings.reduce((a, b) => a + b, 0) / pings.length;
    const variance =
      pings.reduce((a, b) => a + (b - mean) ** 2, 0) / pings.length;
    const stddev = Math.sqrt(variance);

    // Remove pings that are more than 2 standard deviations above the mean
    const non_outlier_pings = pings.filter((ping) => ping <= mean + 2 * stddev);

    const sum = non_outlier_pings.reduce((a, b) => a + b, 0);
    const average = sum / non_outlier_pings.length;
    return average;
  }

  #bleep_server_ping() {
    const start_time_s = Date.now() / 1000;
    const ping_s = this.#server_time_info.ping_s;

    this.#time_sync_channel

      .push("time-ping", {
        time_s: start_time_s,
        ping_s: ping_s,
      })

      .receive("ok", (resp) => {
        const finish_time_s = Date.now() / 1000;
        if (resp.client_timestamp !== start_time_s) {
          console.log("Time sync error: client timestamp mismatch");
        }

        const roundtrip_time_s = finish_time_s - resp.client_timestamp;
        this.#server_time_info.ping_times.enq(roundtrip_time_s);
        const average_ping_time = this.#average_ping_time();
        const average_one_way_trip_time = average_ping_time / 2;
        const delta_s =
          resp.server_timestamp - (start_time_s + average_one_way_trip_time);
        this.#server_time_info.ping_s = average_ping_time;
        this.#server_time_info.delta_s = delta_s;
      })
      .receive("error", (resp) => {
        console.log("Unable to send time sync", resp);
      });
  }

  #handle_server_event_sched_bleep_audio(e) {
    try {
      const user_id = e.user_id;
      const editor_id = e.editor_id;
      const run_id = e.run_id;
      const server_time_s = e.server_time_s;
      this.#prescheduler.schedule(
        user_id,
        editor_id,
        run_id,
        server_time_s,
        this.#server_time_info.delta_s,
        e
      );
    } catch (ex) {
      console.log(`Incoming bleep-audio event error ${ex.message}`);
      console.log(ex);
    }
  }
}

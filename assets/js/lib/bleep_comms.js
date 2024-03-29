import { Socket } from "phoenix";

export default class BleepComms {
  #user_id;
  #prescheduler;
  #bleep_socket;
  #jam_session_channels;
  #time_sync_channel;
  #server_time_info;

  constructor(user_id, prescheduler) {
    this.#user_id = user_id;
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
      delta_s: 0,
      latency_s: 0.05,
      latency_measurement_s: 0.05,
    };

    this.#prepopluate_server_time_info();
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

  #handle_server_event_time_ack(e) {
    [delta_s, single_way_time] = this.#calculate_server_time_delta_and_latency(
      e.client_timestamp,
      e.server_timestamp
    );

    this.#server_time_info = {
      delta_s: delta_s,
      latency_s: e.latency_est,
      latency_measurement_s: single_way_time,
    };
  }

  #prepopluate_server_time_info() {
    this.#time_sync_channel
      .push("time-ping", {
        time_s: Date.now() / 1000,
      })

      .receive("ok", (resp) => {
        [delta_s, single_way_time] =
          this.#calculate_server_time_delta_and_latency(
            resp.client_timestamp,
            resp.server_timestamp
          );
        this.#server_time_info = {
          delta_s: delta_s,
          latency_s: single_way_time,
          latency_measurement_s: single_way_time,
        };
      })
      .receive("error", (resp) => {
        console.log("Unable to send time sync", resp);
      });
  }

  #calculate_server_time_delta_and_latency(
    roundtrip_start_timestamp,
    roundtrip_server_timestamp
  ) {
    const roundtrip_finish_timestamp = Date.now() / 1000;
    const single_way_time =
      (roundtrip_finish_timestamp - roundtrip_start_timestamp) / 2;
    const delta_s =
      roundtrip_finish_timestamp - single_way_time - roundtrip_server_timestamp;

    return [delta_s, single_way_time];
  }

  #start_server_time_info_updater() {
    // prepopluate time info
    [
      2.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.5, 8.0, 8.5, 9.0, 9.5, 10.5, 11.0,
      11.5, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5,
    ].forEach((i) => {
      setTimeout(() => {
        this.#time_sync();
      }, i * 1000);
    });

    // then update every 10s
    setTimeout(() => {
      setInterval(() => {
        this.#time_sync();
      }, 10000);
    }, 15000);
  }

  #time_sync() {
    this.#time_sync_channel
      .push("time-sync", {
        time_s: Date.now() / 1000,
        latency_s: this.#server_time_info.latency_measurement_s,
      })

      .receive("ok", (resp) => {
        this.#handle_server_event_time_ack(resp);
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
      const time_s = e.time_s;
      this.#prescheduler.schedule(
        user_id,
        editor_id,
        run_id,
        time_s,
        this.#server_time_info.delta_s,
        e
      );
    } catch (ex) {
      console.log(`Incoming bleep-audio event error ${ex.message}`);
      console.log(ex);
    }
  }
}

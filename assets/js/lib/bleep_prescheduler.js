// Bleep prescheduler

export default class BleepPrescheduler {
  #bleep_audio;
  #scheduled_events;
  #current_timer;
  #time_deltas;
  #server_time_info;
  #minimum_schedule_requirement_s = 1.5;

  constructor(bleep_audio) {
    this.#bleep_audio = bleep_audio;

    this.#scheduled_events = [];
    this.#current_timer = null;
    this.#time_deltas = new Map();

    this.#server_time_info = {
      delta_s: 0,
      latency_s: 0.05,
      latency_measurement_s: 0.05,
    };
  }

  schedule(user_id, tag, run_id, time, delta, msg) {
    const time_delta_s = this.#get_or_set_time_delta(run_id, delta);

    this.#insert_event(user_id, tag, run_id, time + time_delta_s, msg);
  }

  #get_or_set_time_delta(run_id, delta) {
    const res = this.#time_deltas.get(run_id);
    const now = Date.now() / 1000;

    if (!res) {
      this.#time_deltas.set(run_id, [delta, now]);
      return delta;
    } else {
      const [current_delta, _ts] = res;
      this.#time_deltas.set(run_id, [current_delta, now]);
      return delta;
    }
  }

  cancel_tag(tag) {
    this.#scheduled_events = this.#scheduled_events.filter(
      (e) => e[1].tag !== tag
    );
    this.#schedule_next_event();
  }

  #insert_event(user_id, tag, run_id, time_s, msg) {
    const info = { user_id: user_id, tag: tag, run_id: run_id };
    this.#scheduled_events.push([time_s, info, msg]);
    this.#scheduled_events.sort((a, b) => a[0] - b[0]);
    this.#schedule_next_event(user_id);
  }

  #schedule_next_event(user_id) {
    if (this.#scheduled_events.length === 0) {
      this.#current_timer = null;
      return;
    }

    const [time_s, _info, _msg] = this.#scheduled_events[0];
    if (
      !this.#current_timer ||
      (this.#current_timer && this.#current_timer.time_s > time_s)
    ) {
      this.#add_run_next_event_timer(time_s);
    }
  }

  #add_run_next_event_timer(time_s) {
    if (this.#current_timer) {
      clearTimeout(this.#current_timer.timer_id);
    }
    const now_s = Date.now() / 1000;
    const time_delta_s = time_s - now_s;
    if (time_delta_s < this.#minimum_schedule_requirement_s) {
      this.#run_next_event();
    } else {
      this.#current_timer = {
        time_s: time_s,
        timer_id: setTimeout(() => {
          this.#run_next_event();
        }, time_delta_s * 1000),
      };
    }
  }

  #run_next_event() {
    if (this.#scheduled_events.length === 0) {
      return;
    }
    this.#current_timer = null;
    const [time_s, info, msg] = this.#scheduled_events[0];
    const now_s = Date.now() / 1000;
    const time_delta_s = time_s - now_s;
    if (time_delta_s < this.#minimum_schedule_requirement_s) {
      const [_time_delta_s, _ts] = this.#time_deltas.get(info.run_id);
      const temp_time_delta = 0.1;
      this.#scheduled_events.shift();
      this.#bleep_audio.jsonDispatch(temp_time_delta, msg);
    }
    this.#schedule_next_event();
  }
}

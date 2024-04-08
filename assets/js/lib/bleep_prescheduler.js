// Bleep prescheduler

export default class BleepPrescheduler {
  #bleep_audio;
  #scheduled_events;
  #current_timer;
  #time_deltas;

  #minimum_schedule_requirement_s = 1.2;
  #latency_s = 0.5;

  constructor(bleep_audio) {
    this.#bleep_audio = bleep_audio;
    this.#scheduled_events = [];
    this.#current_timer = null;
    this.#time_deltas = new Map();
    this.#start_gc();
  }

  schedule(user_id, tag, run_id, time_s, time_delta_s, msg) {
    const run_id_cached_delta_s = this.#get_or_set_time_delta(
      run_id,
      time_delta_s
    );
    const adjusted_time_s = time_s + run_id_cached_delta_s + this.#latency_s;
    this.#insert_event(user_id, tag, run_id, adjusted_time_s, msg);
  }

  cancel_tag(tag) {
    this.#scheduled_events = this.#scheduled_events.filter(
      (e) => e[1].tag !== tag
    );
    this.#schedule_next_event();
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
      return current_delta;
    }
  }

  #insert_event(user_id, tag, run_id, adjusted_time_s, msg) {
    const info = { user_id: user_id, tag: tag, run_id: run_id };
    this.#scheduled_events.push([adjusted_time_s, info, msg]);
    this.#scheduled_events.sort((a, b) => a[0] - b[0]);
    this.#schedule_next_event();
  }

  #schedule_next_event() {
    if (this.#scheduled_events.length === 0) {
      this.#clear_current_timer();
      return;
    }

    const [adjusted_time_s, _info, _msg] = this.#scheduled_events[0];
    if (
      !this.#current_timer ||
      (this.#current_timer && this.#current_timer.time_s > adjusted_time_s)
    ) {
      this.#add_run_next_event_timer(adjusted_time_s);
    }
  }

  #clear_current_timer() {
    if (this.#current_timer) {
      clearTimeout(this.#current_timer.timer_id);
    }
    this.#current_timer = null;
  }

  #add_run_next_event_timer(adjusted_time_s) {
    const now_s = Date.now() / 1000;
    const time_delta_s = adjusted_time_s - now_s;
    if (time_delta_s < this.#minimum_schedule_requirement_s) {
      this.#run_next_event();
    } else {
      this.#current_timer = {
        time_s: adjusted_time_s,
        timer_id: setTimeout(() => {
          this.#current_timer = null;
          this.#run_next_event();
        }, (time_delta_s - this.#minimum_schedule_requirement_s) * 1000),
      };
    }
  }

  #run_next_event() {
    this.#clear_current_timer();
    if (this.#scheduled_events.length === 0) {
      console.log("Error in run_next_event: no events scheduled");
      return;
    }
    const [adjusted_time_s, _info, msg] = this.#scheduled_events[0];
    const now_s = Date.now() / 1000;
    const sched_delta_s = adjusted_time_s - now_s;

    if (sched_delta_s < 0) {
      console.log("Late audio event! ", (sched_delta_s * -1).toFixed(3), msg);
    }
    this.#scheduled_events.shift();
    this.#bleep_audio.jsonDispatch(adjusted_time_s, msg);
    this.#schedule_next_event();
  }

  #gc() {
    // stop this.#time_deltas from continuously growing
    // by pruning things that are older than 5 seconds
    const now = Date.now() / 1000;
    for (let [key, [_delta, ts]] of this.#time_deltas) {
      // If the timestamp is less than the given timestamp, delete the entry
      if (ts + 5 < now) {
        this.#time_deltas.delete(key);
      }
    }
  }

  #start_gc() {
    setInterval(() => {
      this.#gc();
    }, 5000);
  }
}

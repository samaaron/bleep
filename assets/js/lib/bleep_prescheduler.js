// Bleep prescheduler

export default class BleepPrescheduler {
  #scheduled_events;
  #bleep;
  #time_deltas;

  constructor(bleep) {
    this.#scheduled_events = new Map();
    this.#bleep = bleep;
    this.#time_deltas = new Map();
  }

  schedule(server_sched_time_s, tag, msg, t_delta_s) {
    const minimum_schedule_requirement_s = 1.5;
    const now = Date.now() / 1000;
    const server_delta_s = server_sched_time_s - now;
    const sched_delta =
      server_delta_s + t_delta_s - minimum_schedule_requirement_s;
    if (sched_delta > 0) {
      //schedule the event for later dispatch
      let timer = setTimeout(() => {
        this.#bleep.jsonDispatch(t_delta_s, msg);
        // Remove the timer from the map when it completes
        this.removeTimer(tag, timer);
      }, sched_delta * 1000);

      if (this.#scheduled_events.has(tag)) {
        let timers = this.#scheduled_events.get(tag);
        timers.push(timer);
      } else {
        this.#scheduled_events.set(tag, [timer]);
      }
    } else {
      // dispatch the event immediately
      this.#bleep.jsonDispatch(t_delta_s, msg);
    }
  }

  removeTimer(tag, timer) {
    if (this.#scheduled_events.has(tag)) {
      let timers = this.#scheduled_events.get(tag);
      timers = timers.filter((t) => t !== timer);
      if (timers.length > 0) {
        this.#scheduled_events.set(tag, timers);
      } else {
        this.#scheduled_events.delete(tag);
      }
    }
  }

  cancelTimers(tag) {
    if (this.#scheduled_events.has(tag)) {
      let timers = this.#scheduled_events.get(tag);
      timers.array.forEach((timer) => {
        clearTimeout(timer);
      });

      this.#scheduled_events.delete(tag);
    }
  }

  time_delta(run_id) {
    const res = this.#time_deltas.get(run_id);

    if (!res) {
      return null;
    } else {
      const now = Date.now() / 1000;
      const [delta, _ts] = res;
      this.#time_deltas.set(run_id, [delta, now]);
      return delta;
    }
  }

  set_time_delta(run_id, delta) {
    const now = Date.now() / 1000;
    this.#time_deltas.set(run_id, [delta, now]);
  }

  gc() {
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

  start_gc() {
    setInterval(() => {
      this.gc();
    }, 5000);
  }
}

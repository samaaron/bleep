// Bleep prescheduler

export default class BleepPrescheduler {
  #scheduled_events;
  #bleep;

  constructor(bleep) {
    this.#scheduled_events = new Map();
    this.#bleep = bleep;
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
        // use most recent time delta as it might have
        // changed since the event was scheduled
        this.#bleep.jsonDispatch(window.bleep_time_info.delta, msg);
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
}

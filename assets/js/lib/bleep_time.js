const BleepTime = {
  timer: null,

  mounted() {
    window.bleep_time_info = {
      delta: 0,
      latency: 0.05,
      latency_measurement: 0,
    };

    setTimeout(() => {
      this.pushEvent("bleep-time", {
        time_s: Date.now() / 1000,
        latency: 0.05,
      });
    }, 2000);

    [4, 4.5, 5, 5.5, 6, 6.5, 7.5, 8, 8.5, 9, 9.5, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5, 15].forEach((i) => {
      setTimeout(() => {
        this.pushEvent("bleep-time", {
          time_s: Date.now() / 1000,
          latency: window.bleep_time_info.latency_measurement,
        });
      }, i * 1000);
    });

    this.timer = setInterval(() => {
      // Send current timestamp in seconds
      // This will then be similarly timestamped by the live view process
      // and sent back as a "bleep-time-ack" JS event (currently handled in app.js)
      // Also thread through the latest latency measurement
      this.pushEvent("bleep-time", {
        time_s: Date.now() / 1000,
        latency: window.bleep_time_info.latency_measurement,
      });
    }, 10000);
  },

  destroyed() {
    // Clear the interval when the LiveView is unmounted
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  },
};

export default BleepTime;

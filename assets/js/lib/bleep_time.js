const BleepTime = {
  timer: null,

  mounted() {
    if (!this.timer) {
      console.log("timer is null");
    }
    this.pushEvent("bleep-time", { time: Date.now() / 1000.0 });

    setTimeout(() => {
      this.pushEvent("bleep-time", { time: Date.now() / 1000.0 });
    }, 3000)

    this.timer = setInterval(() => {
      // Send current timestamp in seconds
      // This will then be similarly timestamped by the live view process
      // and sent back as a "bleep-time-ack" JS event (currently handled in app.js)
      this.pushEvent("bleep-time", { time: Date.now() / 1000.0 });
    }, 10000); // 10000 milliseconds = 10 seconds
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

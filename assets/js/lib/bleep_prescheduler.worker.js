// Bleep Prescheduler Worker

let scheduledEvents = [];
let currentTimer = null;
let timeDeltas = new Map();
const minimumScheduleRequirementS = 0.1;
const latencyS = 0.5;

self.onmessage = function (e) {
  const data = e.data;
  switch (data.action) {
    case "schedule":
      scheduleEvent(
        data.userId,
        data.editorId,
        data.runId,
        data.runTag,
        data.timeS,
        data.timeDeltaS,
        data.msg
      );
      break;
    case "cancelEditorTag":
      cancelEditorTag(data.editorId, data.runTag);
      break;
    case "cancelEditor":
      cancelEditor(data.editorId);
      break;
    case "cancelAllTags":
      cancelAllTags();
      break;
    case "resetTimeDeltas":
      resetTimeDeltas();
      break;
    case "gc":
      gc();
      break;
  }
};

function getOrSetTimeDelta(runId, delta) {
  const res = timeDeltas.get(runId);
  const now = Date.now() / 1000;

  if (!res) {
    timeDeltas.set(runId, [delta, now]);
    return delta;
  } else {
    const [currentDelta, _ts] = res;
    timeDeltas.set(runId, [currentDelta, now]);
    return currentDelta;
  }
}

function scheduleEvent(
  userId,
  editorId,
  runId,
  runTag,
  timeS,
  timeDeltaS,
  msg
) {
  const runIdCachedDeltaS = getOrSetTimeDelta(runId, timeDeltaS);
  const adjustedTimeS = timeS + runIdCachedDeltaS + latencyS;
  insertEvent(userId, editorId, runId, runTag, adjustedTimeS, msg);
}

function insertEvent(userId, editorId, runId, runTag, adjustedTimeS, msg) {
  const info = { userId, editorId, runTag, runId };
  scheduledEvents.push([adjustedTimeS, info, msg]);
  scheduledEvents.sort((a, b) => a[0] - b[0]);
  scheduleNextEvent();
}

function scheduleNextEvent() {
  if (scheduledEvents.length === 0) {
    clearCurrentTimer();
    return;
  }

  const [adjustedTimeS] = scheduledEvents[0];
  if (!currentTimer || (currentTimer && currentTimer.timeS > adjustedTimeS)) {
    addRunNextEventTimer(adjustedTimeS);
  }
}

function clearCurrentTimer() {
  if (currentTimer) {
    clearTimeout(currentTimer.timerId);
  }
  currentTimer = null;
}

function addRunNextEventTimer(adjustedTimeS) {
  const nowS = Date.now() / 1000;
  const timeDeltaS = adjustedTimeS - nowS;
  if (timeDeltaS < minimumScheduleRequirementS) {
    runNextEvent();
  } else {
    currentTimer = {
      timeS: adjustedTimeS,
      timerId: setTimeout(() => {
        currentTimer = null;
        runNextEvent();
      }, (timeDeltaS - minimumScheduleRequirementS) * 1000),
    };
  }
}

function runNextEvent() {
  clearCurrentTimer();
  if (scheduledEvents.length === 0) {
    return;
  }

  const [adjustedTimeS, _info, msg] = scheduledEvents.shift();

  const nowS = Date.now() / 1000;
  const schedDeltaS = adjustedTimeS - nowS;
  if (schedDeltaS < 0) {
    self.postMessage({
      action: "logLate",
      schedDeltaS,
      msg,
    });
  }

  self.postMessage({ action: "timedDispatch", adjustedTimeS, msg });
  scheduleNextEvent();
}

function cancelEditorTag(editorId, runTag) {
  scheduledEvents = scheduledEvents.filter(
    (e) => e[1].runTag !== runTag || e[1].editorId !== editorId
  );
  scheduleNextEvent();
}

function cancelEditor(editorId) {
  scheduledEvents = scheduledEvents.filter((e) => e[1].editorId !== editorId);
  scheduleNextEvent();
}

function cancelAllTags() {
  scheduledEvents = [];
  scheduleNextEvent();
}

function resetTimeDeltas() {
  timeDeltas = new Map();
}

function gc() {
  // stop this.#time_deltas from continuously growing
  // by pruning things that are older than 5 seconds
  const now = Date.now() / 1000;
  for (let [key, [_delta, ts]] of timeDeltas) {
    // If the timestamp is less than the given timestamp, delete the entry
    if (ts + 5 < now) {
      timeDeltas.delete(key);
    }
  }
}

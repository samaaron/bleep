// Bleep Prescheduler Worker

let scheduledEvents = [];
let currentTimer = null;
let cachedTimeDelta = null;
const minimumScheduleRequirementS = 0.2;
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
      resetTimeDelta();
      break;
  }
};

function getOrSetTimeDelta(delta) {
  if (!cachedTimeDelta) {
    cachedTimeDelta = delta;
  }

  return cachedTimeDelta;
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
  const runIdCachedDeltaS = getOrSetTimeDelta(timeDeltaS);
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

function resetTimeDelta() {
  cachedTimeDelta = null;
}

import {
  pushTo,
  replyTo,
  type PhoenixFrame,
  type PhoenixReplyStatus,
} from "./phoenix";
import {
  emptyLobbySnapshot,
  finishedMissingParticipantSnapshot,
  finishedRestartSnapshot,
  finishedSnapshot,
  invalidPhaseSnapshots,
  mediaNoMetaSnapshot,
  mediaNoPlayerSnapshot,
  mediaNoPreviewSnapshot,
  mediaPlayingSnapshot,
  mediaPreviewUpdatedSnapshot,
  mediaSnapshot,
  ownerLobbySnapshot,
  playerLobbySnapshot,
  readyControlsSnapshot,
  readyPlayingSnapshot,
  readySnapshot,
  resultsNoWinnerSnapshot,
  resultsSnapshot,
  score12Snapshot,
  score3Snapshot,
  score7Snapshot,
  scoreMissingSnapshot,
  scoreUndefinedSnapshot,
  singleParticipantSnapshot,
  timelineChallengingOwnSnapshot,
  timelineMixedSnapshot,
  timelineNoTrackSnapshot,
  timelineOtherAssumptionSnapshot,
  timelineOwnAssumptionSnapshot,
  timelinePermissionsUndefinedSnapshot,
  timelineSlotZeroSnapshot,
  timerSnapshot,
  timerUpdatedSnapshot,
  undefinedParticipantsSnapshot,
  waitingActiveBobSnapshot,
  waitingActiveSnapshot,
  waitingPassiveBobSnapshot,
  waitingPassiveSnapshot,
} from "./mock/room/messages";
import { phxJoin } from "./mock/room/phx_join";

type Reply = {
  status: PhoenixReplyStatus;
  response: unknown;
};

type Handler = (
  client: { send: (data: string | ArrayBuffer) => void },
  frame: PhoenixFrame,
) => void;

const okReply: Reply = {
  status: "ok",
  response: {},
};

const missingRoomReply: Reply = {
  status: "error",
  response: { reason: "game_not_found" },
};

export const handlers: Record<string, Record<string, Handler>> = {
  phoenix: {
    heartbeat(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-1": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: phxJoin }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-missing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, missingRoomReply));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-owner-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: ownerLobbySnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-player-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: playerLobbySnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-empty-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: emptyLobbySnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-single-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: singleParticipantSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-undefined-participants": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: undefinedParticipantsSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-3": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: score3Snapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-missing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: scoreMissingSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-undefined": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: scoreUndefinedSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-updates": {
    phx_join(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, { status: "ok", response: score7Snapshot }));
      client.send(pushTo(topic, { event: "state", payload: score12Snapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: readySnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-active": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingActiveSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-passive": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingPassiveSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-active-bob": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingActiveBobSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-passive-bob": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingPassiveBobSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-results": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: resultsSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-results-no-winner": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: resultsNoWinnerSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-finished": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: finishedSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-finished-restart": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: finishedRestartSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-finished-missing-participant": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: finishedMissingParticipantSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-start-game": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: ownerLobbySnapshot }));
    },
    start_game(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, { event: "state", payload: waitingActiveSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-advance-turn": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingActiveSnapshot }));
    },
    advance_turn(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, { event: "state", payload: readyControlsSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready-controls": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: readyControlsSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready-playing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: readyPlayingSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-start-playback": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: readyControlsSnapshot }));
    },
    start_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, { event: "state", payload: readyPlayingSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-pause-playback": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: readyPlayingSnapshot }));
    },
    pause_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, { event: "state", payload: readyControlsSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-own-assumption": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: timelineOwnAssumptionSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-challenging-own": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: timelineChallengingOwnSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-slot-zero": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: timelineSlotZeroSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-other-assumption": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: timelineOtherAssumptionSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-mixed": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: timelineMixedSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-no-permissions": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: timelinePermissionsUndefinedSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-no-track": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: timelineNoTrackSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: mediaSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-no-preview": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: mediaNoPreviewSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-preview-update": {
    phx_join(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, { status: "ok", response: mediaSnapshot }));

      queueMicrotask(() => {
        client.send(pushTo(topic, {
          event: "state",
          payload: mediaPreviewUpdatedSnapshot,
        }));
      });
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-playing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: mediaPlayingSnapshot }));
    },
    pause_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, { event: "state", payload: mediaSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-no-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: mediaNoPlayerSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-no-meta": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: mediaNoMetaSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-toggle": {
    phx_join(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, { status: "ok", response: mediaSnapshot }));

      queueMicrotask(() => {
        client.send(pushTo(topic, {
          event: "state",
          payload: mediaPlayingSnapshot,
        }));

        queueMicrotask(() => {
          client.send(pushTo(topic, {
            event: "state",
            payload: mediaSnapshot,
          }));
        });
      });
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timer": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: timerSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timer-update": {
    phx_join(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, { status: "ok", response: readySnapshot }));

      queueMicrotask(() => {
        client.send(pushTo(topic, {
          event: "state",
          payload: timerUpdatedSnapshot,
        }));
      });
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-0": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[0] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-1": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[1] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-2": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[2] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-3": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[3] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-4": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[4] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-5": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[5] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-6": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[6] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-7": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: invalidPhaseSnapshots[7] }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
};

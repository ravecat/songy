import {
  pushTo,
  replyTo,
  type PhoenixFrame,
  type PhoenixReplyStatus,
} from "./phoenix";
import {
  challengingTimelineOwnAssumptionSnapshot,
  challengingActivePlayerSnapshot,
  challengingPlaybackControlsActivePlayerSnapshot,
  challengingTimerSnapshot,
  finishedCanRestartSnapshot,
  finishedMissingParticipantSnapshot,
  finishedSnapshot,
  invalidTurnPhaseSnapshots,
  mediaNoMetaSnapshot,
  mediaNoPlayerSnapshot,
  mediaNoPreviewSnapshot,
  mediaPlayingSnapshot,
  mediaSnapshot,
  readyPlaybackControlsSnapshot,
  readyPlaybackControlsActivePlayerSnapshot,
  readyPlaybackPlayingSnapshot,
  readySnapshot,
  readyTimelineMixedSnapshot,
  readyTimelineNoTrackSnapshot,
  readyTimelineOtherAssumptionSnapshot,
  readyTimelineOwnAssumptionSnapshot,
  readyTimelinePermissionsUndefinedSnapshot,
  readyTimelineSlotZeroSnapshot,
  resultsControlsActivePlayerSnapshot,
  resultsNoWinnerSnapshot,
  resultsActivePlayerWinsSnapshot,
  waitingEmptySnapshot,
  waitingOwnerCanStartGameSnapshot,
  waitingParticipantsUndefinedSnapshot,
  waitingScoreMissingSnapshot,
  waitingScoreThreeSnapshot,
  waitingScoresUndefinedSnapshot,
  waitingSingleParticipantSnapshot,
  waitingSnapshot,
  waitingTurnActivePlayerSnapshot,
  waitingTurnActiveSnapshot,
  waitingTurnPassivePlayerSnapshot,
  waitingTurnPassiveSnapshot,
} from "~fixtures/room/messages";

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

export const handlers: Record<string, Record<string, Handler>> = {
  phoenix: {
    heartbeat(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-1": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-missing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "error",
        response: { reason: "game_not_found" },
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-owner-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingOwnerCanStartGameSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-player-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingSnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-empty-lobby": {
    phx_join(client, frame) {
      client.send(replyTo(frame, { status: "ok", response: waitingEmptySnapshot }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-single-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingSingleParticipantSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-undefined-participants": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingParticipantsUndefinedSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-3": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingScoreThreeSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-missing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingScoreMissingSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-score-undefined": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingScoresUndefinedSnapshot,
      }));
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
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingTurnActiveSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-passive": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingTurnPassiveSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-active-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingTurnActivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-waiting-passive-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingTurnPassivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-results": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: resultsActivePlayerWinsSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-results-no-winner": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: resultsNoWinnerSnapshot,
      }));
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
      client.send(replyTo(frame, {
        status: "ok",
        response: finishedCanRestartSnapshot,
      }));
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
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingOwnerCanStartGameSnapshot,
      }));
    },
    start_game(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, {
        event: "state",
        payload: waitingTurnActiveSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-advance-turn": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: waitingTurnActiveSnapshot,
      }));
    },
    advance_turn(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, {
        event: "state",
        payload: readyPlaybackControlsSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready-controls": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyPlaybackControlsSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready-playing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyPlaybackPlayingSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-ready-controls-active-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyPlaybackControlsActivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-start-playback": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyPlaybackControlsSnapshot,
      }));
    },
    start_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, {
        event: "state",
        payload: readyPlaybackPlayingSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-pause-playback": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyPlaybackPlayingSnapshot,
      }));
    },
    pause_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, {
        event: "state",
        payload: readyPlaybackControlsSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-own-assumption": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelineOwnAssumptionSnapshot,
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
        response: challengingTimelineOwnAssumptionSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-slot-zero": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelineSlotZeroSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-other-assumption": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelineOtherAssumptionSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-mixed": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelineMixedSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-no-permissions": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelinePermissionsUndefinedSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timeline-no-track": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: readyTimelineNoTrackSnapshot,
      }));
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
      client.send(replyTo(frame, {
        status: "ok",
        response: mediaNoPreviewSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-playing": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: mediaPlayingSnapshot,
      }));
    },
    pause_playback(client, frame) {
      const [, , topic] = frame;

      client.send(replyTo(frame, okReply));
      client.send(pushTo(topic, {
        event: "state",
        payload: mediaSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-no-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: mediaNoPlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-media-no-meta": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: mediaNoMetaSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-timer": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: challengingTimerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-challenging-active-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: challengingActivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-challenging-controls-active-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: challengingPlaybackControlsActivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-results-controls-active-player": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: resultsControlsActivePlayerSnapshot,
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-0": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[0],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-1": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[1],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-2": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[2],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-3": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[3],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-4": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[4],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-5": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[5],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-6": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[6],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
  "room:room-invalid-phase-7": {
    phx_join(client, frame) {
      client.send(replyTo(frame, {
        status: "ok",
        response: invalidTurnPhaseSnapshots[7],
      }));
    },
    phx_leave(client, frame) {
      client.send(replyTo(frame, okReply));
    },
  },
};

import {
  snapshotPayloadSchema,
  turnSchema,
  type Permissions,
} from "~contracts";
import { zocker } from "zocker";

import { tracks } from "../tracks";
import { users } from "../users";

const gameShape = snapshotPayloadSchema.shape.game.shape;
const permissionsShape = snapshotPayloadSchema.shape.permissions;
const turnShape = snapshotPayloadSchema.shape.game.shape.turn.options[0].shape;

// Stable absolute deadline keeps timer fixtures deterministic with fake timers.
const challengeDeadlineAtMs = Date.parse("2026-01-01T00:00:12.000Z");
const defaultCreatedAt = "2026-03-23T12:00:00.000Z";

const defaultUsers = [
  users.alice,
  users.bob,
  users.carol,
  users.dan,
  users.erin,
  users.frank,
  users.gina,
];

const defaultParticipants = Object.fromEntries(
  defaultUsers.map((user) => [user.id, user]),
);

const defaultQueue = defaultUsers.map((user) => user.id);

const defaultQueueActivePlayerFirst = [
  users.bob.id,
  ...defaultQueue.filter((userId) => userId !== users.bob.id),
];

const defaultScores = {
  [users.alice.id]: 8,
  [users.bob.id]: 10,
  [users.carol.id]: 3,
  [users.dan.id]: 9,
  [users.erin.id]: 6,
  [users.frank.id]: 5,
  [users.gina.id]: 4,
};

const defaultTimelines = {
  [users.alice.id]: [tracks.timelineOne, tracks.timelineTwo],
  [users.bob.id]: [tracks.timelineOne, tracks.timelineTwo],
  [users.carol.id]: [],
  [users.dan.id]: [tracks.timelineTwo],
  [users.erin.id]: [tracks.timelineOne],
  [users.frank.id]: [],
  [users.gina.id]: [tracks.timelineTwo],
};

const defaultResultsAssumptions = {
  1: users.alice.id,
  2: users.bob.id,
  3: users.carol.id,
  4: users.dan.id,
  5: users.erin.id,
  6: users.frank.id,
};

const defaultPermissions = {
  can_control_playback: false,
  can_advance_turn: false,
  can_start_game: false,
  can_start_turn: false,
  can_restart_game: false,
  can_see_assumptions: false,
  can_make_assumptions: false,
} satisfies Permissions;

const waitingTurn = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "waiting")
  .supply(turnShape.assumptions, {})
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const readyTurn = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "ready")
  .supply(turnShape.assumptions, {})
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const readyTurnOwnAssumption = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "ready")
  .supply(turnShape.assumptions, {
    1: users.alice.id,
  })
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const readyTurnSlotZero = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "ready")
  .supply(turnShape.assumptions, {
    0: users.alice.id,
  })
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const readyTurnOtherAssumption = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "ready")
  .supply(turnShape.assumptions, {
    0: users.bob.id,
  })
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const readyTurnMixedAssumptions = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "ready")
  .supply(turnShape.assumptions, {
    0: users.bob.id,
    2: users.alice.id,
  })
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const challengingTurn = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "challenging")
  .supply(turnShape.assumptions, {})
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, challengeDeadlineAtMs)
  .generate();

const challengingTurnOwnAssumption = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "challenging")
  .supply(turnShape.assumptions, {
    1: users.alice.id,
  })
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, challengeDeadlineAtMs)
  .generate();

const resultsTurnWin = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "results")
  .supply(turnShape.assumptions, defaultResultsAssumptions)
  .supply(turnShape.winner_id, users.alice.id)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const resultsTurnNoWinner = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "results")
  .supply(turnShape.assumptions, defaultResultsAssumptions)
  .supply(turnShape.winner_id, null)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const finishedTurn = zocker(turnSchema)
  .setSeed(2)
  .supply(turnShape.phase, "results")
  .supply(turnShape.assumptions, {})
  .supply(turnShape.winner_id, users.bob.id)
  .supply(turnShape.deadline_at_ms, null)
  .generate();

const playbackTrack = {
  ...tracks.current,
  meta: {
    ...tracks.current.meta,
    preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
  },
};

const waitingSnapshotZock = zocker(snapshotPayloadSchema)
  .setSeed(1)
  .supply(gameShape.id, "room-1")
  .supply(gameShape.owner_id, users.alice.id)
  .supply(gameShape.max_participants, 8)
  .supply(gameShape.max_score, 10)
  .supply(gameShape.status, "waiting")
  .supply(gameShape.participants, defaultParticipants)
  .supply(gameShape.scores, defaultScores)
  .supply(gameShape.player, { is_playback: false })
  .supply(gameShape.timelines, defaultTimelines)
  .supply(gameShape.created_at, defaultCreatedAt)
  .supply(gameShape.queue, defaultQueue)
  .supply(gameShape.cursor, 0)
  .supply(gameShape.track, null)
  .supply(gameShape.turn, null)
  .supply(permissionsShape, defaultPermissions);

const inProgressSnapshotZock = waitingSnapshotZock.supply(
  gameShape.status,
  "in_progress",
);

const waitingTurnSnapshotZock = inProgressSnapshotZock.supply(
  gameShape.turn,
  waitingTurn,
);

const readySnapshotZock = inProgressSnapshotZock.supply(
  gameShape.turn,
  readyTurn,
);

const mediaSnapshotZock = waitingSnapshotZock
  .supply(gameShape.track, playbackTrack)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_control_playback: true,
  });

const challengingSnapshotZock = inProgressSnapshotZock.supply(
  gameShape.turn,
  challengingTurn,
);

const resultsSnapshotZock = inProgressSnapshotZock.supply(
  gameShape.track,
  tracks.result,
);

const finishedSnapshotZock = waitingSnapshotZock
  .supply(gameShape.status, "finished")
  .supply(gameShape.track, tracks.result)
  .supply(gameShape.turn, finishedTurn);

export const waitingSnapshot = waitingSnapshotZock.generate();

export const waitingOwnerCanStartGameSnapshot = waitingSnapshotZock
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_start_game: true,
  })
  .generate();

export const waitingEmptySnapshot = waitingSnapshotZock
  .supply(gameShape.participants, {})
  .supply(gameShape.scores, {})
  .supply(gameShape.queue, [])
  .generate();

export const waitingSingleParticipantSnapshot = waitingSnapshotZock
  .supply(gameShape.participants, {
    [users.alice.id]: users.alice,
  })
  .supply(gameShape.scores, {
    [users.alice.id]: 7,
  })
  .supply(gameShape.queue, [users.alice.id])
  .generate();

export const waitingParticipantsUndefinedSnapshot = waitingSnapshotZock
  .supply(gameShape.participants, undefined as never)
  .supply(gameShape.queue, [])
  .generate();

export const waitingScoreThreeSnapshot = waitingSnapshotZock
  .supply(gameShape.scores, {
    [users.alice.id]: 3,
  })
  .generate();

export const waitingScoreMissingSnapshot = waitingSnapshotZock
  .supply(gameShape.scores, {
    [users.bob.id]: 5,
  })
  .generate();

export const waitingScoresUndefinedSnapshot = waitingSnapshotZock
  .supply(gameShape.scores, undefined as never)
  .generate();

export const waitingTurnPassiveSnapshot = waitingTurnSnapshotZock.generate();

export const waitingTurnActiveSnapshot = waitingTurnSnapshotZock
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_start_turn: true,
  })
  .generate();

export const waitingTurnActivePlayerSnapshot = waitingTurnSnapshotZock
  .supply(gameShape.cursor, 1)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_start_turn: true,
  })
  .generate();

export const waitingTurnPassivePlayerSnapshot = waitingTurnSnapshotZock
  .supply(gameShape.cursor, 1)
  .generate();

export const readySnapshot = readySnapshotZock.generate();

export const readyPlaybackControlsSnapshot = readySnapshotZock
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_control_playback: true,
  })
  .generate();

export const readyPlaybackPlayingSnapshot = readySnapshotZock
  .supply(gameShape.player, { is_playback: true })
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_control_playback: true,
  })
  .generate();

export const readyPlaybackControlsActivePlayerSnapshot = readySnapshotZock
  .supply(gameShape.cursor, 1)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_control_playback: true,
  })
  .generate();

export const readyTimelineNoTrackSnapshot = readySnapshotZock
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const readyTimelineOwnAssumptionSnapshot = readySnapshotZock
  .supply(gameShape.turn, readyTurnOwnAssumption)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const readyTimelineSlotZeroSnapshot = readySnapshotZock
  .supply(gameShape.turn, readyTurnSlotZero)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const readyTimelineOtherAssumptionSnapshot = readySnapshotZock
  .supply(gameShape.turn, readyTurnOtherAssumption)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const readyTimelineMixedSnapshot = readySnapshotZock
  .supply(gameShape.turn, readyTurnMixedAssumptions)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const readyTimelinePermissionsUndefinedSnapshot = readySnapshotZock
  .supply(permissionsShape, undefined as never)
  .generate();

export const mediaSnapshot = mediaSnapshotZock.generate();

export const mediaPlayingSnapshot = mediaSnapshotZock
  .supply(gameShape.player, { is_playback: true })
  .generate();

export const mediaNoPreviewSnapshot = mediaSnapshotZock
  .supply(gameShape.track, {
    ...playbackTrack,
    meta: {},
  })
  .generate();

export const mediaNoPlayerSnapshot = mediaSnapshotZock
  .supply(gameShape.player, undefined as never)
  .generate();

export const mediaNoMetaSnapshot = mediaSnapshotZock
  .supply(gameShape.track, {
    ...playbackTrack,
    meta: undefined,
  } as never)
  .generate();

export const challengingTimerSnapshot = challengingSnapshotZock.generate();

export const challengingTimelineOwnAssumptionSnapshot = challengingSnapshotZock
  .supply(gameShape.queue, defaultQueueActivePlayerFirst)
  .supply(gameShape.turn, challengingTurnOwnAssumption)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_make_assumptions: true,
  })
  .generate();

export const challengingActivePlayerSnapshot = challengingSnapshotZock
  .supply(gameShape.cursor, 1)
  .generate();

export const challengingPlaybackControlsActivePlayerSnapshot =
  challengingSnapshotZock
    .supply(gameShape.cursor, 1)
    .supply(permissionsShape, {
      ...defaultPermissions,
      can_control_playback: true,
    })
    .generate();

export const resultsActivePlayerWinsSnapshot = resultsSnapshotZock
  .supply(gameShape.turn, resultsTurnWin)
  .generate();

export const resultsNoWinnerSnapshot = resultsSnapshotZock
  .supply(gameShape.turn, resultsTurnNoWinner)
  .generate();

export const resultsControlsActivePlayerSnapshot = resultsSnapshotZock
  .supply(gameShape.cursor, 1)
  .supply(gameShape.turn, resultsTurnWin)
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_advance_turn: true,
    can_control_playback: true,
  })
  .generate();

export const finishedSnapshot = finishedSnapshotZock.generate();

export const finishedCanRestartSnapshot = finishedSnapshotZock
  .supply(permissionsShape, {
    ...defaultPermissions,
    can_restart_game: true,
  })
  .generate();

export const finishedMissingParticipantSnapshot = finishedSnapshotZock
  .supply(gameShape.participants, {
    [users.alice.id]: users.alice,
    [users.bob.id]: users.bob,
  })
  .supply(gameShape.scores, {
    [users.alice.id]: 7,
    [users.bob.id]: 10,
    [users.carol.id]: 3,
  })
  .supply(gameShape.queue, [users.alice.id, users.bob.id, users.carol.id])
  .generate();

export const invalidTurnPhaseSnapshots = [
  undefined,
  null,
  "turn_countdown",
  "",
  "unknown_phase",
  123,
  {},
  [],
].map((phase) =>
  readySnapshotZock
    .supply(gameShape.turn, {
      ...readyTurn,
      phase,
    } as never)
    .generate(),
);

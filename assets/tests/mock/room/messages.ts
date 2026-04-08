import {
  roomSnapshot,
  tracks,
  users,
} from "./fixtures";

const readyTurn = {
  phase: "ready",
  assumptions: {},
  winner_id: null,
};

const waitingTurn = {
  phase: "waiting",
  assumptions: {},
  winner_id: null,
};

const resultsAssumptions = {
  1: users.alice.uuid,
  2: users.bob.uuid,
};

const finishedScores = {
  [users.alice.uuid]: 7,
  [users.bob.uuid]: 10,
  [users.carol.uuid]: 3,
};

const roomQueue = [users.alice.uuid, users.bob.uuid, users.carol.uuid];

const previewTrack = {
  ...tracks.media,
  meta: {
    ...tracks.media.meta,
  },
};

const previewTrackWithoutPreview = {
  ...tracks.media,
  meta: {},
};

const previewTrackWithoutMeta = {
  ...tracks.media,
  meta: undefined,
};

const previewTrackUpdated = {
  ...tracks.media,
  meta: {
    preview_url: "https://new-preview-url.m4a",
  },
};

const timer12Ms = Date.parse("2026-01-01T00:00:12.000Z");
const timer8Ms = Date.parse("2026-01-01T00:00:08.000Z");

const {
  [users.carol.uuid]: _carol,
  ...finishedParticipantsWithoutCarol
} = roomSnapshot.game.participants;

const { player: _player, ...mediaGameWithoutPlayer } = {
  ...roomSnapshot.game,
  track: previewTrack,
  player: {
    ...roomSnapshot.game.player,
    is_playback: false,
  },
};

export const ownerLobbySnapshot = {
  ...roomSnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_start_game: true,
  },
};

export const playerLobbySnapshot = roomSnapshot;

export const emptyLobbySnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    participants: {},
    queue: [],
    scores: {},
  },
};

export const singleParticipantSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    participants: {
      [users.alice.uuid]: users.alice,
    },
    queue: [users.alice.uuid],
    scores: {
      [users.alice.uuid]: 7,
    },
  },
};

export const undefinedParticipantsSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    participants: undefined,
    queue: [],
  },
};

export const score3Snapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    scores: {
      [users.alice.uuid]: 3,
    },
  },
};

export const score7Snapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    scores: {
      [users.alice.uuid]: 7,
    },
  },
};

export const score12Snapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    scores: {
      [users.alice.uuid]: 12,
    },
  },
};

export const scoreMissingSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    scores: {
      [users.bob.uuid]: 5,
    },
  },
};

export const scoreUndefinedSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    scores: undefined,
  },
};

export const readySnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    turn: readyTurn,
  },
};

export const waitingActiveSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    queue: roomQueue,
    cursor: 0,
    turn: waitingTurn,
  },
  permissions: {
    ...roomSnapshot.permissions,
    can_start_turn: true,
  },
};

export const waitingPassiveSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    queue: roomQueue,
    cursor: 0,
    turn: waitingTurn,
  },
};

export const waitingActiveBobSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    queue: roomQueue,
    cursor: 1,
    turn: waitingTurn,
  },
  permissions: {
    ...roomSnapshot.permissions,
    can_start_turn: true,
  },
};

export const waitingPassiveBobSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    queue: roomQueue,
    cursor: 1,
    turn: waitingTurn,
  },
};

export const resultsSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    track: tracks.result,
    turn: {
      phase: "results",
      assumptions: resultsAssumptions,
      winner_id: users.alice.uuid,
    },
  },
};

export const resultsNoWinnerSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "in_progress",
    track: tracks.result,
    turn: {
      phase: "results",
      assumptions: resultsAssumptions,
      winner_id: null,
    },
  },
};

export const finishedSnapshot = {
  ...roomSnapshot,
  game: {
    ...roomSnapshot.game,
    status: "finished",
    scores: finishedScores,
    turn: {
      phase: "results",
      assumptions: {},
      winner_id: users.bob.uuid,
      deadline_at_ms: null,
    },
  },
};

export const finishedRestartSnapshot = {
  ...finishedSnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_restart_game: true,
  },
};

export const finishedMissingParticipantSnapshot = {
  ...finishedSnapshot,
  game: {
    ...finishedSnapshot.game,
    participants: finishedParticipantsWithoutCarol,
  },
};

export const readyControlsSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...readySnapshot.game,
    player: {
      ...roomSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const readyPlayingSnapshot = {
  ...readyControlsSnapshot,
  game: {
    ...readyControlsSnapshot.game,
    player: {
      ...roomSnapshot.game.player,
      is_playback: true,
    },
  },
};

export const timelineOwnAssumptionSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    turn: {
      ...readyTurn,
      assumptions: {
        1: users.alice.uuid,
      },
    },
  },
};

export const timelineChallengingOwnSnapshot = {
  ...timelineOwnAssumptionSnapshot,
  game: {
    ...timelineOwnAssumptionSnapshot.game,
    queue: [users.bob.uuid, users.alice.uuid, users.carol.uuid],
    cursor: 0,
    turn: {
      ...timelineOwnAssumptionSnapshot.game.turn,
      phase: "challenging",
    },
  },
};

export const timelineSlotZeroSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    turn: {
      ...readyTurn,
      assumptions: {
        0: users.alice.uuid,
      },
    },
  },
};

export const timelineOtherAssumptionSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    turn: {
      ...readyTurn,
      assumptions: {
        0: users.bob.uuid,
      },
    },
  },
};

export const timelineMixedSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    turn: {
      ...readyTurn,
      assumptions: {
        0: users.bob.uuid,
        2: users.alice.uuid,
      },
    },
  },
};

export const timelinePermissionsUndefinedSnapshot = {
  ...readySnapshot,
  permissions: undefined,
};

export const timelineNoTrackSnapshot = {
  ...readySnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_make_assumptions: true,
  },
};

export const mediaSnapshot = {
  ...roomSnapshot,
  permissions: {
    ...roomSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...roomSnapshot.game,
    track: previewTrack,
    player: {
      ...roomSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const mediaPreviewUpdatedSnapshot = {
  ...mediaSnapshot,
  game: {
    ...mediaSnapshot.game,
    track: previewTrackUpdated,
  },
};

export const mediaPlayingSnapshot = {
  ...mediaSnapshot,
  game: {
    ...mediaSnapshot.game,
    player: {
      ...roomSnapshot.game.player,
      is_playback: true,
    },
  },
};

export const mediaNoPreviewSnapshot = {
  ...mediaSnapshot,
  game: {
    ...mediaSnapshot.game,
    track: previewTrackWithoutPreview,
  },
};

export const mediaNoPlayerSnapshot = {
  ...mediaSnapshot,
  game: mediaGameWithoutPlayer,
};

export const mediaNoMetaSnapshot = {
  ...mediaSnapshot,
  game: {
    ...mediaSnapshot.game,
    track: previewTrackWithoutMeta,
  },
};

export const timerSnapshot = {
  ...readySnapshot,
  game: {
    ...readySnapshot.game,
    turn: {
      phase: "challenging",
      deadline_at_ms: timer12Ms,
    },
  },
};

export const timerUpdatedSnapshot = {
  ...readySnapshot,
  game: {
    ...readySnapshot.game,
    turn: {
      phase: "challenging",
      deadline_at_ms: timer8Ms,
    },
  },
};

export const invalidPhaseSnapshots = [
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: undefined,
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: null,
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: "turn_countdown",
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: "",
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: "unknown_phase",
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: 123,
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: {},
      },
    },
  },
  {
    ...readySnapshot,
    game: {
      ...readySnapshot.game,
      turn: {
        ...readySnapshot.game.turn,
        phase: [],
      },
    },
  },
];

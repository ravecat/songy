import { tracks } from "../tracks";
import { users } from "../users";
import { basePermissions } from "../permissions";

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

export const waitingSnapshot = {
  game: {
    id: "room-1",
    owner_id: users.alice.id,
    max_participants: 8,
    max_score: 10,
    status: "waiting",
    participants: defaultParticipants,
    scores: defaultScores,
    player: {
      is_playback: false,
    },
    timelines: defaultTimelines,
    created_at: "2026-03-23T12:00:00.000Z",
    queue: defaultQueue,
    cursor: 0,
    track: null,
    turn: null,
  },
  permissions: basePermissions,
  timer: null,
} satisfies Record<string, unknown>;

export const waitingOwnerCanStartGameSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_start_game: true,
  },
};

export const waitingEmptySnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    participants: {},
    queue: [],
    scores: {},
  },
};

export const waitingSingleParticipantSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    participants: {
      [users.alice.id]: users.alice,
    },
    queue: [users.alice.id],
    scores: {
      [users.alice.id]: 7,
    },
  },
};

export const waitingParticipantsUndefinedSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    participants: undefined,
    queue: [],
  },
};

export const waitingScoreThreeSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    scores: {
      [users.alice.id]: 3,
    },
  },
};

export const waitingScoreMissingSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    scores: {
      [users.bob.id]: 5,
    },
  },
};

export const waitingScoresUndefinedSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    scores: undefined,
  },
};

export const readySnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    turn: {
      phase: "ready",
      assumptions: {},
      winner_id: null,
    },
  },
};

export const waitingTurnActiveSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_start_turn: true,
  },
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "waiting",
      assumptions: {},
      winner_id: null,
    },
  },
};

export const waitingTurnPassiveSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "waiting",
      assumptions: {},
      winner_id: null,
    },
  },
};

export const waitingTurnActivePlayerSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_start_turn: true,
  },
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    queue: defaultQueue,
    cursor: 1,
    turn: {
      phase: "waiting",
      assumptions: {},
      winner_id: null,
    },
  },
};

export const waitingTurnPassivePlayerSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    queue: defaultQueue,
    cursor: 1,
    turn: {
      phase: "waiting",
      assumptions: {},
      winner_id: null,
    },
  },
};

export const resultsActivePlayerWinsSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    track: tracks.result,
    turn: {
      phase: "results",
      assumptions: defaultResultsAssumptions,
      winner_id: users.alice.id,
    },
  },
};

export const resultsNoWinnerSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "in_progress",
    track: tracks.result,
    turn: {
      phase: "results",
      assumptions: defaultResultsAssumptions,
      winner_id: null,
    },
  },
};

export const finishedSnapshot = {
  ...waitingSnapshot,
  game: {
    ...waitingSnapshot.game,
    status: "finished",
    scores: defaultScores,
    turn: {
      phase: "results",
      assumptions: {},
      winner_id: users.bob.id,
      deadline_at_ms: null,
    },
  },
};

export const finishedCanRestartSnapshot = {
  ...finishedSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_restart_game: true,
  },
};

export const finishedMissingParticipantSnapshot = {
  ...finishedSnapshot,
  game: {
    ...finishedSnapshot.game,
    participants: {
      [users.alice.id]: users.alice,
      [users.bob.id]: users.bob,
    },
    queue: [users.alice.id, users.bob.id, users.carol.id],
    scores: {
      [users.alice.id]: 7,
      [users.bob.id]: 10,
      [users.carol.id]: 3,
    },
  },
};

export const readyPlaybackControlsSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...readySnapshot.game,
    player: {
      ...waitingSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const readyPlaybackPlayingSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...readySnapshot.game,
    player: {
      ...waitingSnapshot.game.player,
      is_playback: true,
    },
  },
};

export const readyPlaybackControlsActivePlayerSnapshot = {
  ...readyPlaybackControlsSnapshot,
  game: {
    ...readyPlaybackControlsSnapshot.game,
    queue: defaultQueue,
    cursor: 1,
  },
};

export const readyTimelineOwnAssumptionSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "ready",
      assumptions: {
        1: users.alice.id,
      },
      winner_id: null,
    },
  },
};

export const challengingTimelineOwnAssumptionSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    queue: defaultQueueActivePlayerFirst,
    cursor: 0,
    turn: {
      phase: "challenging",
      assumptions: {
        1: users.alice.id,
      },
      winner_id: null,
    },
  },
};

export const readyTimelineSlotZeroSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "ready",
      assumptions: {
        0: users.alice.id,
      },
      winner_id: null,
    },
  },
};

export const readyTimelineOtherAssumptionSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "ready",
      assumptions: {
        0: users.bob.id,
      },
      winner_id: null,
    },
  },
};

export const readyTimelineMixedSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
  game: {
    ...readySnapshot.game,
    queue: defaultQueue,
    cursor: 0,
    turn: {
      phase: "ready",
      assumptions: {
        0: users.bob.id,
        2: users.alice.id,
      },
      winner_id: null,
    },
  },
};

export const readyTimelinePermissionsUndefinedSnapshot = {
  ...readySnapshot,
  permissions: undefined,
};

export const readyTimelineNoTrackSnapshot = {
  ...readySnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_make_assumptions: true,
  },
};

const playbackTrack = {
  ...tracks.current,
  meta: {
    ...tracks.current.meta,
    preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
  },
};

export const mediaSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...waitingSnapshot.game,
    track: {
      ...playbackTrack,
      meta: {
        ...playbackTrack.meta,
      },
    },
    player: {
      ...waitingSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const mediaPlayingSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...waitingSnapshot.game,
    track: {
      ...playbackTrack,
      meta: {
        ...playbackTrack.meta,
      },
    },
    player: {
      ...waitingSnapshot.game.player,
      is_playback: true,
    },
  },
};

export const mediaNoPreviewSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...waitingSnapshot.game,
    track: {
      ...playbackTrack,
      meta: {},
    },
    player: {
      ...waitingSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const mediaNoPlayerSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...waitingSnapshot.game,
    track: {
      ...playbackTrack,
      meta: {
        ...playbackTrack.meta,
      },
    },
    player: undefined,
  },
};

export const mediaNoMetaSnapshot = {
  ...waitingSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
  game: {
    ...waitingSnapshot.game,
    track: {
      ...playbackTrack,
      meta: undefined,
    },
    player: {
      ...waitingSnapshot.game.player,
      is_playback: false,
    },
  },
};

export const challengingTimerSnapshot = {
  ...readySnapshot,
  game: {
    ...readySnapshot.game,
    turn: {
      phase: "challenging",
      deadline_at_ms: Date.parse("2026-01-01T00:00:12.000Z"),
    },
  },
};

export const challengingActivePlayerSnapshot = {
  ...challengingTimerSnapshot,
  game: {
    ...challengingTimerSnapshot.game,
    queue: defaultQueue,
    cursor: 1,
  },
};

export const challengingPlaybackControlsActivePlayerSnapshot = {
  ...challengingActivePlayerSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
  },
};

export const resultsControlsActivePlayerSnapshot = {
  ...resultsActivePlayerWinsSnapshot,
  permissions: {
    ...waitingSnapshot.permissions,
    can_control_playback: true,
    can_advance_turn: true,
  },
  game: {
    ...resultsActivePlayerWinsSnapshot.game,
    queue: defaultQueue,
    cursor: 1,
  },
};

export const invalidTurnPhaseSnapshots = [
  undefined,
  null,
  "turn_countdown",
  "",
  "unknown_phase",
  123,
  {},
  [],
].map((phase) => ({
  ...readySnapshot,
  game: {
    ...readySnapshot.game,
    turn: {
      phase,
      assumptions: {},
      winner_id: null,
    },
  },
}));

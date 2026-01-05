import { describe, test, expect } from 'vitest';
import { computePermissions } from '~shared/authorization';
import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

const ownerUser: User = {
  uuid: 'owner',
  name: 'Owner',
  avatar_url: 'https://example.com/owner.jpg',
};

const playerUser: User = {
  uuid: 'player',
  name: 'Player',
  avatar_url: 'https://example.com/player.jpg',
};

const challengerUser: User = {
  uuid: 'challenger',
  name: 'Challenger',
  avatar_url: 'https://example.com/challenger.jpg',
};

const baseGame: Game = {
  id: 'game-1',
  owner_id: ownerUser.uuid,
  participants: [ownerUser, playerUser, challengerUser],
  max_participants: 10,
  max_score: 10,
  created_at: new Date().toISOString(),
  status: GAME_STATUS.WAITING,
  player: null,
  turn: null,
  timelines: {},
  scores: {},
  queue: [ownerUser.uuid, playerUser.uuid, challengerUser.uuid],
  cursor: 0,
  track: null,
};

interface PermissionsFixture {
  state: GAME_STATUS;
  phase: TURN_PHASE | null;
  expected: {
    canControlPlayback: boolean;
    canAdvanceTurn: boolean;
    canStartGame: boolean;
    canAdvanceFromWaiting: boolean;
    canRestartGame: boolean;
  };
}

const ownerCases: PermissionsFixture[] = [
  {
    state: GAME_STATUS.WAITING,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: true,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.WAITING,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: true,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.READY,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.CHALLENGING,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.RESULTS,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: true,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.FINISHED,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: true,
    },
  },
];

const playerCases: PermissionsFixture[] = [
  {
    state: GAME_STATUS.WAITING,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.WAITING,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: true,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.READY,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: true,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.CHALLENGING,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.RESULTS,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: true,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.FINISHED,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: true,
    },
  },
];

const challengerCases: PermissionsFixture[] = [
  {
    state: GAME_STATUS.WAITING,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.WAITING,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.READY,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.CHALLENGING,
    expected: {
      canControlPlayback: true,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: false,
    },
  },
  {
    state: GAME_STATUS.FINISHED,
    phase: null,
    expected: {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: true,
    },
  },
];

const buildGame = ({
  state,
  phase,
  ownerId,
  queue,
  cursor,
}: {
  state: GAME_STATUS;
  phase: TURN_PHASE | null;
  ownerId: string;
  queue: string[];
  cursor: number;
}): Game => ({
  ...baseGame,
  status: state,
  owner_id: ownerId,
  queue,
  cursor,
  turn:
    state === GAME_STATUS.IN_PROGRESS && phase
      ? { phase, timeline: [], assumptions: [] }
      : null,
});

const ownerGame = (state: GAME_STATUS, phase: TURN_PHASE | null): Game =>
  buildGame({
    state,
    phase,
    ownerId: ownerUser.uuid,
    queue: [playerUser.uuid, challengerUser.uuid, ownerUser.uuid],
    cursor: 0,
  });

const playerGame = (state: GAME_STATUS, phase: TURN_PHASE | null): Game =>
  buildGame({
    state,
    phase,
    ownerId: ownerUser.uuid,
    queue: [playerUser.uuid, challengerUser.uuid],
    cursor: 0,
  });

const challengerGame = (state: GAME_STATUS, phase: TURN_PHASE | null): Game =>
  buildGame({
    state,
    phase,
    ownerId: ownerUser.uuid,
    queue: [playerUser.uuid, challengerUser.uuid],
    cursor: 0,
  });

const expectFlags = (
  permissions: ReturnType<typeof computePermissions>,
  expected: {
    canControlPlayback: boolean;
    canAdvanceTurn: boolean;
    canStartGame: boolean;
    canAdvanceFromWaiting: boolean;
    canRestartGame: boolean;
  }
) => {
  expect(permissions.canControlPlayback).toBe(expected.canControlPlayback);
  expect(permissions.canAdvanceTurn).toBe(expected.canAdvanceTurn);
  expect(permissions.canStartGame).toBe(expected.canStartGame);
  expect(permissions.canAdvanceFromWaiting).toBe(expected.canAdvanceFromWaiting);
  expect(permissions.canRestartGame).toBe(expected.canRestartGame);
};

describe('permissions', () => {
  describe('owner permissions', () => {
    ownerCases.forEach(({ state, phase, expected }) => {
      test(`${state}/${phase ?? 'nil'}`, () => {
        const game = ownerGame(state, phase);
        const permissions = computePermissions(game, ownerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('player permissions', () => {
    playerCases.forEach(({ state, phase, expected }) => {
      test(`${state}/${phase ?? 'nil'}`, () => {
        const game = playerGame(state, phase);
        const permissions = computePermissions(game, playerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('challenger permissions', () => {
    challengerCases.forEach(({ state, phase, expected }) => {
      test(`${state}/${phase ?? 'nil'}`, () => {
        const game = challengerGame(state, phase);
        const permissions = computePermissions(game, challengerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('waiting phase', () => {
    const waitingGame = buildGame({
      state: GAME_STATUS.IN_PROGRESS,
      phase: TURN_PHASE.WAITING,
      ownerId: ownerUser.uuid,
      queue: [playerUser.uuid, ownerUser.uuid, challengerUser.uuid],
      cursor: 0,
    });

    test('active player can control playback and advance from waiting', () => {
      const permissions = computePermissions(waitingGame, playerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: true,
        canRestartGame: false,
      });
    });

    test('owner can control playback and advance from waiting', () => {
      const permissions = computePermissions(waitingGame, ownerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: true,
        canRestartGame: false,
      });
    });

    test('challenger cannot control playback or advance', () => {
      const permissions = computePermissions(waitingGame, challengerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });
  });

  describe('ready phase', () => {
    const readyGame = buildGame({
      state: GAME_STATUS.IN_PROGRESS,
      phase: TURN_PHASE.READY,
      ownerId: ownerUser.uuid,
      queue: [playerUser.uuid, ownerUser.uuid, challengerUser.uuid],
      cursor: 0,
    });

    test('active player can control playback and advance', () => {
      const permissions = computePermissions(readyGame, playerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: true,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('owner cannot advance in ready phase', () => {
      const permissions = computePermissions(readyGame, ownerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('challenger cannot control playback or advance', () => {
      const permissions = computePermissions(readyGame, challengerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });
  });

  describe('challenging phase', () => {
    const playerActiveGame = buildGame({
      state: GAME_STATUS.IN_PROGRESS,
      phase: TURN_PHASE.CHALLENGING,
      ownerId: ownerUser.uuid,
      queue: [playerUser.uuid, ownerUser.uuid, challengerUser.uuid],
      cursor: 0,
    });

    test('active player cannot control playback', () => {
      const permissions = computePermissions(playerActiveGame, playerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('owner can control playback', () => {
      const permissions = computePermissions(playerActiveGame, ownerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('challenger can control playback', () => {
      const permissions = computePermissions(playerActiveGame, challengerUser);

      expectFlags(permissions, {
        canControlPlayback: true,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });
  });

  describe('results phase', () => {
    const resultsGame = buildGame({
      state: GAME_STATUS.IN_PROGRESS,
      phase: TURN_PHASE.RESULTS,
      ownerId: ownerUser.uuid,
      queue: [playerUser.uuid, ownerUser.uuid, challengerUser.uuid],
      cursor: 0,
    });

    test('active player can advance to next turn', () => {
      const permissions = computePermissions(resultsGame, playerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: true,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('owner can advance to next turn', () => {
      const permissions = computePermissions(resultsGame, ownerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: true,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('challenger cannot advance', () => {
      const permissions = computePermissions(resultsGame, challengerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });
  });

  test('game finished shows play again', () => {
    const game = { ...baseGame, status: GAME_STATUS.FINISHED as const };

    const ownerPermissions = computePermissions(game, ownerUser);
    expectFlags(ownerPermissions, {
      canControlPlayback: false,
      canAdvanceTurn: false,
      canStartGame: false,
      canAdvanceFromWaiting: false,
      canRestartGame: true,
    });

    const playerPermissions = computePermissions(game, playerUser);
    expect(playerPermissions.canRestartGame).toBe(true);
  });

  describe('edge cases', () => {
    test('handles null game gracefully', () => {
      const permissions = computePermissions(null, ownerUser);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('handles null user gracefully', () => {
      const permissions = computePermissions(baseGame, null);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });

    test('handles both null game and user', () => {
      const permissions = computePermissions(null, null);

      expectFlags(permissions, {
        canControlPlayback: false,
        canAdvanceTurn: false,
        canStartGame: false,
        canAdvanceFromWaiting: false,
        canRestartGame: false,
      });
    });
  });

  test('all permission objects have required fields', () => {
    const game = buildGame({
      state: GAME_STATUS.IN_PROGRESS,
      phase: TURN_PHASE.READY,
      ownerId: ownerUser.uuid,
      queue: [ownerUser.uuid, playerUser.uuid],
      cursor: 0,
    });

    const permissions = computePermissions(game, ownerUser);

    expect(permissions).toHaveProperty('canControlPlayback');
    expect(permissions).toHaveProperty('canAdvanceTurn');
    expect(permissions).toHaveProperty('canStartGame');
    expect(permissions).toHaveProperty('canAdvanceFromWaiting');
    expect(permissions).toHaveProperty('canRestartGame');
  });
});

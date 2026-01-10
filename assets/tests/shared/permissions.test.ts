import { describe, test, expect } from 'vitest';
import { getPermissions, defaultPermissions } from '~shared/authorization';
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
    state: GAME_STATUS.IN_PROGRESS,
    phase: TURN_PHASE.RESULTS,
    expected: {
      canControlPlayback: false,
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

// Helper to create a game with specific state
function createGame(
  state: GAME_STATUS,
  phase: TURN_PHASE | null,
  ownerId: string,
  queue: string[],
  cursor: number
): Game {
  return {
    ...baseGame,
    owner_id: ownerId,
    status: state,
    queue,
    cursor,
    turn: phase ? { phase } : null,
  };
}

const expectFlags = (
  permissions: ReturnType<typeof getPermissions>,
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
        const game = createGame(state, phase, ownerUser.uuid, [ownerUser.uuid, playerUser.uuid, challengerUser.uuid], 0);
        const permissions = getPermissions(game, ownerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('player permissions', () => {
    playerCases.forEach(({ state, phase, expected }) => {
      test(`${state}/${phase ?? 'nil'}`, () => {
        const game = createGame(state, phase, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
        const permissions = getPermissions(game, playerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('challenger permissions', () => {
    challengerCases.forEach(({ state, phase, expected }) => {
      test(`${state}/${phase ?? 'nil'}`, () => {
        const game = createGame(state, phase, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
        const permissions = getPermissions(game, challengerUser);
        expectFlags(permissions, expected);
      });
    });
  });

  describe('waiting phase', () => {
    test('active player can control playback and advance from waiting', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.WAITING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, playerUser);
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceFromWaiting).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(false);
    });

    test('owner can control playback and advance from waiting', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.WAITING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, ownerUser);
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceFromWaiting).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(false);
    });

    test('challenger cannot control playback or advance', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.WAITING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, challengerUser);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceFromWaiting).toBe(false);
    });
  });

  describe('ready phase', () => {
    test('active player can control playback and advance', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.READY, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, playerUser);
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(true);
    });

    test('owner cannot advance in ready phase', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.READY, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, ownerUser);
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(false);
    });

    test('challenger cannot control playback or advance', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.READY, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, challengerUser);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
    });
  });

  describe('challenging phase', () => {
    test('active player cannot control playback', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.CHALLENGING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, playerUser);
      expect(permissions.canControlPlayback).toBe(false);
    });

    test('owner can control playback', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.CHALLENGING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, ownerUser);
      expect(permissions.canControlPlayback).toBe(true);
    });

    test('challenger can control playback', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.CHALLENGING, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, challengerUser);
      expect(permissions.canControlPlayback).toBe(true);
    });
  });

  describe('results phase', () => {
    test('active player can advance to next turn', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.RESULTS, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, playerUser);
      expect(permissions.canAdvanceTurn).toBe(true);
    });

    test('owner can advance to next turn', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.RESULTS, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, ownerUser);
      expect(permissions.canAdvanceTurn).toBe(true);
    });

    test('challenger cannot advance', () => {
      const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.RESULTS, ownerUser.uuid, [playerUser.uuid, challengerUser.uuid], 0);
      const permissions = getPermissions(game, challengerUser);
      expect(permissions.canAdvanceTurn).toBe(false);
    });
  });

  describe('edge cases', () => {
    test('handles null game gracefully', () => {
      const permissions = getPermissions(null, ownerUser);
      expect(permissions).toEqual(defaultPermissions);
    });

    test('handles null user gracefully', () => {
      const game = createGame(GAME_STATUS.WAITING, null, ownerUser.uuid, [ownerUser.uuid], 0);
      const permissions = getPermissions(game, null);
      expect(permissions).toEqual(defaultPermissions);
    });

    test('handles both null game and user', () => {
      const permissions = getPermissions(null, null);
      expect(permissions).toEqual(defaultPermissions);
    });
  });

  test('game finished shows play again', () => {
    const game = createGame(GAME_STATUS.FINISHED, null, ownerUser.uuid, [ownerUser.uuid, playerUser.uuid], 0);
    const permissions = getPermissions(game, ownerUser);
    expect(permissions.canRestartGame).toBe(true);
  });

  test('all permission objects have required fields', () => {
    const game = createGame(GAME_STATUS.IN_PROGRESS, TURN_PHASE.WAITING, ownerUser.uuid, [ownerUser.uuid], 0);
    const permissions = getPermissions(game, ownerUser);
    expect(permissions).toHaveProperty('canControlPlayback');
    expect(permissions).toHaveProperty('canAdvanceTurn');
    expect(permissions).toHaveProperty('canStartGame');
    expect(permissions).toHaveProperty('canAdvanceFromWaiting');
    expect(permissions).toHaveProperty('canRestartGame');
  });
});

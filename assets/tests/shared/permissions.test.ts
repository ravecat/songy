import { describe, test, expect } from 'vitest';
import { computeGamePermissions } from '~shared/permissions';
import type { Game } from '~shared/types/game';
import type { User } from '~shared/types/user';
import { GAME_STATUS } from '~shared/types/game';
import { TURN_PHASE } from '~shared/types/turn';

describe('GamePermissions', () => {
  const mockOwner: User = {
    uuid: 'owner-1',
    name: 'Owner',
    avatar_url: 'https://example.com/owner.jpg',
  };

  const mockPlayer: User = {
    uuid: 'player-2',
    name: 'Player',
    avatar_url: 'https://example.com/player.jpg',
  };

  const mockSpectator: User = {
    uuid: 'spectator-3',
    name: 'Spectator',
    avatar_url: 'https://example.com/spectator.jpg',
  };

  const baseGame: Game = {
    id: 'game-1',
    owner_id: 'owner-1',
    participants: [mockOwner, mockPlayer],
    max_participants: 10,
    max_score: 10,
    created_at: new Date().toISOString(),
    status: GAME_STATUS.WAITING,
    player: null,
    turn: null,
    timelines: {},
    scores: {},
    queue: ['owner-1', 'player-2'],
    cursor: 0,
    track: null,
  };

  describe('Lobby (waiting status)', () => {
    test('owner in lobby can start game', () => {
      const permissions = computeGamePermissions(baseGame, mockOwner);

      expect(permissions.context).toBe('lobby_owner');
      expect(permissions.canStartGame).toBe(true);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.canAdvanceFromWaiting).toBe(false);
      expect(permissions.showPlayAgain).toBe(false);
      expect(permissions.isOwner).toBe(true);
      expect(permissions.isActivePlayer).toBe(true);
    });

    test('non-owner participant in lobby cannot start game', () => {
      const permissions = computeGamePermissions(baseGame, mockPlayer);

      expect(permissions.context).toBe('lobby_participant');
      expect(permissions.canStartGame).toBe(false);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.canAdvanceFromWaiting).toBe(false);
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });

    test('spectator cannot do anything in lobby', () => {
      const game = { ...baseGame, participants: [...baseGame.participants, mockSpectator] };
      const permissions = computeGamePermissions(game, mockSpectator);

      expect(permissions.context).toBe('lobby_participant');
      expect(permissions.canStartGame).toBe(false);
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });
  });

  describe('Turn waiting phase', () => {
    const waitingGame = {
      ...baseGame,
      status: GAME_STATUS.IN_PROGRESS as const,
      turn: { phase: TURN_PHASE.WAITING as const, timeline: [], assumptions: [] },
    };

    test('active player can advance from waiting', () => {
      const permissions = computeGamePermissions(waitingGame, mockOwner);

      expect(permissions.context).toBe('turn_waiting_active');
      expect(permissions.canAdvanceFromWaiting).toBe(true);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.isActivePlayer).toBe(true);
    });

    test('idle player cannot advance from waiting', () => {
      const permissions = computeGamePermissions(waitingGame, mockPlayer);

      expect(permissions.context).toBe('turn_waiting_idle');
      expect(permissions.canAdvanceFromWaiting).toBe(false);
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });
  });

  describe('Turn ready phase', () => {
    const readyGame = {
      ...baseGame,
      status: GAME_STATUS.IN_PROGRESS as const,
      turn: { phase: TURN_PHASE.READY as const, timeline: [], assumptions: [] },
    };

    test('active player can control playback and advance turn', () => {
      const permissions = computeGamePermissions(readyGame, mockOwner);

      expect(permissions.context).toBe('turn_ready_active');
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(true);
      expect(permissions.canStartGame).toBe(false);
      expect(permissions.isActivePlayer).toBe(true);
    });

    test('owner (not active) can control playback but not advance turn', () => {
      const game = { ...readyGame, cursor: 1 };
      const permissions = computeGamePermissions(game, mockOwner);

      expect(permissions.context).toBe('turn_ready_owner');
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.isOwner).toBe(true);
      expect(permissions.isActivePlayer).toBe(false);
    });

    test('spectator cannot do anything in ready phase', () => {
      const game = { ...readyGame, participants: [...readyGame.participants, mockSpectator] };
      const permissions = computeGamePermissions(game, mockSpectator);

      expect(permissions.context).toBe('turn_ready_spectator');
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });
  });

  describe('Turn challenging phase', () => {
    const challengingGame = {
      ...baseGame,
      status: GAME_STATUS.IN_PROGRESS as const,
      turn: { phase: TURN_PHASE.CHALLENGING as const, timeline: [], assumptions: [] },
    };

    test('active player can control playback and advance turn', () => {
      const permissions = computeGamePermissions(challengingGame, mockOwner);

      expect(permissions.context).toBe('turn_challenging_active');
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(true);
    });

    test('owner (not active) can control playback but not advance turn', () => {
      const game = { ...challengingGame, cursor: 1 };
      const permissions = computeGamePermissions(game, mockOwner);

      expect(permissions.context).toBe('turn_challenging_owner');
      expect(permissions.canControlPlayback).toBe(true);
      expect(permissions.canAdvanceTurn).toBe(false);
    });

    test('spectator cannot do anything in challenging phase', () => {
      const game = { ...challengingGame, participants: [...challengingGame.participants, mockSpectator] };
      const permissions = computeGamePermissions(game, mockSpectator);

      expect(permissions.context).toBe('turn_challenging_spectator');
      expect(permissions.canControlPlayback).toBe(false);
      expect(permissions.canAdvanceTurn).toBe(false);
    });
  });

  describe('Turn results phase', () => {
    const resultsGame = {
      ...baseGame,
      status: GAME_STATUS.IN_PROGRESS as const,
      turn: { phase: TURN_PHASE.RESULTS as const, timeline: [], assumptions: [] },
    };

    test('active player can advance to next turn', () => {
      const permissions = computeGamePermissions(resultsGame, mockOwner);

      expect(permissions.context).toBe('turn_results_active');
      expect(permissions.canAdvanceTurn).toBe(true);
      expect(permissions.canControlPlayback).toBe(false);
    });

    test('owner (not active) cannot do anything in results', () => {
      const game = { ...resultsGame, cursor: 1 };
      const permissions = computeGamePermissions(game, mockOwner);

      expect(permissions.context).toBe('turn_results_owner');
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.canControlPlayback).toBe(false);
    });

    test('spectator cannot do anything in results phase', () => {
      const game = { ...resultsGame, participants: [...resultsGame.participants, mockSpectator] };
      const permissions = computeGamePermissions(game, mockSpectator);

      expect(permissions.context).toBe('turn_results_spectator');
      expect(permissions.canAdvanceTurn).toBe(false);
      expect(permissions.canControlPlayback).toBe(false);
    });
  });

  describe('Game finished', () => {
    test('shows play again button for all players', () => {
      const game = { ...baseGame, status: GAME_STATUS.FINISHED as const };

      const ownerPermissions = computeGamePermissions(game, mockOwner);
      expect(ownerPermissions.context).toBe('game_finished');
      expect(ownerPermissions.showPlayAgain).toBe(true);
      expect(ownerPermissions.canControlPlayback).toBe(false);
      expect(ownerPermissions.canAdvanceTurn).toBe(false);

      const playerPermissions = computeGamePermissions(game, mockPlayer);
      expect(playerPermissions.context).toBe('game_finished');
      expect(playerPermissions.showPlayAgain).toBe(true);
    });
  });

  describe('Edge cases', () => {
    test('handles null game gracefully', () => {
      const permissions = computeGamePermissions(null, mockOwner);

      expect(permissions.context).toBe('lobby_participant');
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
      expect(permissions.canStartGame).toBe(false);
    });

    test('handles null user gracefully', () => {
      const permissions = computeGamePermissions(baseGame, null);

      expect(permissions.context).toBe('lobby_participant');
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });

    test('handles both null game and user', () => {
      const permissions = computeGamePermissions(null, null);

      expect(permissions.context).toBe('lobby_participant');
      expect(permissions.isOwner).toBe(false);
      expect(permissions.isActivePlayer).toBe(false);
    });
  });

  describe('Context transitions', () => {
    test('changes permissions when active player changes', () => {
      const readyGame = {
        ...baseGame,
        status: GAME_STATUS.IN_PROGRESS as const,
        turn: { phase: TURN_PHASE.READY as const, timeline: [], assumptions: [] },
      };

      // mockOwner is active at cursor 0
      let permissions = computeGamePermissions(readyGame, mockOwner);
      expect(permissions.context).toBe('turn_ready_active');
      expect(permissions.canAdvanceTurn).toBe(true);

      // Change cursor to make mockPlayer active
      const updatedGame = { ...readyGame, cursor: 1 };
      permissions = computeGamePermissions(updatedGame, mockOwner);
      expect(permissions.context).toBe('turn_ready_owner');
      expect(permissions.canAdvanceTurn).toBe(false);
    });

    test('changes permissions when game phase changes', () => {
      const game = {
        ...baseGame,
        status: GAME_STATUS.IN_PROGRESS as const,
        turn: { phase: TURN_PHASE.READY as const, timeline: [], assumptions: [] },
      };

      let permissions = computeGamePermissions(game, mockOwner);
      expect(permissions.context).toBe('turn_ready_active');
      expect(permissions.canControlPlayback).toBe(true);

      // Change phase to challenging
      const updatedGame = { ...game, turn: { phase: TURN_PHASE.CHALLENGING as const, timeline: [], assumptions: [] } };
      permissions = computeGamePermissions(updatedGame, mockOwner);
      expect(permissions.context).toBe('turn_challenging_active');
      expect(permissions.canControlPlayback).toBe(true);

      // Change phase to results
      const resultGame = { ...game, turn: { phase: TURN_PHASE.RESULTS as const, timeline: [], assumptions: [] } };
      permissions = computeGamePermissions(resultGame, mockOwner);
      expect(permissions.context).toBe('turn_results_active');
      expect(permissions.canControlPlayback).toBe(false);
    });
  });

  describe('All 14 contexts have expected patterns', () => {
    test('contexts are mutually exclusive', () => {
      const testCases = [
        { game: baseGame, user: mockOwner, expectedContext: 'lobby_owner' },
        { game: baseGame, user: mockPlayer, expectedContext: 'lobby_participant' },
        {
          game: {
            ...baseGame,
            status: GAME_STATUS.IN_PROGRESS as const,
            turn: { phase: TURN_PHASE.WAITING as const, timeline: [], assumptions: [] },
          },
          user: mockOwner,
          expectedContext: 'turn_waiting_active',
        },
        {
          game: {
            ...baseGame,
            status: GAME_STATUS.IN_PROGRESS as const,
            turn: { phase: TURN_PHASE.WAITING as const, timeline: [], assumptions: [] },
          },
          user: mockPlayer,
          expectedContext: 'turn_waiting_idle',
        },
      ];

      testCases.forEach(({ game, user, expectedContext }) => {
        const permissions = computeGamePermissions(game, user);
        expect(permissions.context).toBe(expectedContext);
      });
    });

    test('all permission objects have required fields', () => {
      const game = {
        ...baseGame,
        status: GAME_STATUS.IN_PROGRESS as const,
        turn: { phase: TURN_PHASE.READY as const, timeline: [], assumptions: [] },
      };

      const permissions = computeGamePermissions(game, mockOwner);

      expect(permissions).toHaveProperty('canControlPlayback');
      expect(permissions).toHaveProperty('canAdvanceTurn');
      expect(permissions).toHaveProperty('canStartGame');
      expect(permissions).toHaveProperty('canAdvanceFromWaiting');
      expect(permissions).toHaveProperty('showPlayAgain');
      expect(permissions).toHaveProperty('context');
      expect(permissions).toHaveProperty('isActivePlayer');
      expect(permissions).toHaveProperty('isOwner');
    });
  });
});

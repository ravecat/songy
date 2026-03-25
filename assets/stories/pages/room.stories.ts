import type { Component } from "svelte";
import type { Decorator, Meta, StoryObj } from "@storybook/svelte-vite";
import type { Game, Permissions, User } from "~contracts";
import Room from "~components/room.svelte";
import GameContextDecorator from "../decorators/game_provider_decorator.svelte";
import MediaProviderDecorator from "../decorators/media_provider_decorator.svelte";
import QrContextDecorator from "../decorators/qr_context_decorator.svelte";
import ScopeContextDecorator from "../decorators/scope_context_decorator.svelte";
import { game, permissions, users } from "../mocks";

type Args = {
  game: Game;
  permissions: Permissions;
  user: User | null;
};

const decorator = (fn: Decorator<Args>) => fn;
const RoomStory = Room as unknown as Component<Args>;

const meta = {
  title: "Pages/Room",
  component: RoomStory,
  args: {
    game,
    permissions,
    user: users.alice,
  },
  decorators: [
    decorator(() => ({
      Component: QrContextDecorator,
      props: {},
    })),
    decorator((_, { args }) => ({
      Component: ScopeContextDecorator,
      props: {
        user: args.user,
      },
    })),
    decorator(() => ({
      Component: MediaProviderDecorator,
      props: {},
    })),
    decorator((_, { args }) => ({
      Component: GameContextDecorator,
      props: {
        game: args.game,
        permissions: args.permissions,
      },
    })),
  ],
} satisfies Meta<Args>;

export default meta;

type Story = StoryObj<typeof meta>;

export const OwnerLobby: Story = {
  name: "Lobby/Owner",
  args: {
    game,
    permissions: {
      ...permissions,
      can_start_game: true,
    },
    user: users.alice,
  },
};

export const PlayerLobby: Story = {
  name: "Lobby/Player",
  args: {
    game,
    permissions,
    user: users.bob,
  },
};

export const ChallengerLobby: Story = {
  name: "Lobby/Challenger",
  args: {
    game,
    permissions,
    user: users.carol,
  },
};

export const OwnerWaiting: Story = {
  name: "Waiting/Owner",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      turn: {
        phase: "waiting",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: false,
      can_advance_turn: true,
      can_start_game: false,
      can_start_turn: true,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.alice,
  },
};

export const PlayerWaiting: Story = {
  name: "Waiting/Player",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      turn: {
        phase: "waiting",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: false,
      can_advance_turn: true,
      can_start_game: false,
      can_start_turn: true,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.bob,
  },
};

export const ChallengerWaiting: Story = {
  name: "Waiting/Challenger",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      turn: {
        phase: "waiting",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.carol,
  },
};

export const OwnerReady: Story = {
  name: "Ready/Owner",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "ready",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.alice,
  },
};

export const PlayerReady: Story = {
  name: "Ready/Player",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "ready",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: false,
      can_make_assumptions: true,
    } satisfies Permissions,
    user: users.bob,
  },
};

export const ChallengerReady: Story = {
  name: "Ready/Challenger",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "ready",
        assumptions: {},
        winner_id: null,
      },
    } satisfies Game,
    permissions,
    user: users.carol,
  },
};

export const OwnerChallenging: Story = {
  name: "Challenging/Owner",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "challenging",
        assumptions: {
          1: users.carol.uuid,
        },
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.alice,
  },
};

export const PlayerChallenging: Story = {
  name: "Challenging/Player",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "challenging",
        assumptions: {
          1: users.carol.uuid,
        },
        winner_id: null,
      },
    } satisfies Game,
    permissions,
    user: users.bob,
  },
};

export const ChallengerChallenging: Story = {
  name: "Challenging/Challenger",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      timelines: {
        ...game.timelines,
        [users.bob.uuid]: [
          {
            id: "track-1",
            title: "Take On Me",
            artist: "a-ha",
            year: 1985,
            cover_url: null,
            meta: {},
          },
          {
            id: "track-2",
            title: "Feel Good Inc.",
            artist: "Gorillaz",
            year: 2005,
            cover_url: null,
            meta: {},
          },
        ],
      },
      turn: {
        phase: "challenging",
        assumptions: {
          1: users.carol.uuid,
        },
        winner_id: null,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: false,
      can_make_assumptions: true,
    } satisfies Permissions,
    user: users.carol,
  },
};

export const OwnerResults: Story = {
  name: "Results/Owner",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      track: {
        id: "track-results",
        title: "Midnight City",
        artist: "M83",
        year: 2011,
        cover_url: null,
        meta: {},
      },
      turn: {
        phase: "results",
        assumptions: {
          1: users.bob.uuid,
          3: users.carol.uuid,
        },
        winner_id: users.carol.uuid,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: true,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: true,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.alice,
  },
};

export const PlayerResults: Story = {
  name: "Results/Player",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      track: {
        id: "track-results",
        title: "Midnight City",
        artist: "M83",
        year: 2011,
        cover_url: null,
        meta: {},
      },
      turn: {
        phase: "results",
        assumptions: {
          1: users.bob.uuid,
          3: users.carol.uuid,
        },
        winner_id: users.carol.uuid,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: true,
      can_advance_turn: true,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: true,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.bob,
  },
};

export const ChallengerResults: Story = {
  name: "Results/Challenger",
  args: {
    game: {
      ...game,
      status: "in_progress",
      queue: [users.bob.uuid, users.carol.uuid, users.alice.uuid],
      cursor: 0,
      track: {
        id: "track-results",
        title: "Midnight City",
        artist: "M83",
        year: 2011,
        cover_url: null,
        meta: {},
      },
      turn: {
        phase: "results",
        assumptions: {
          1: users.bob.uuid,
          3: users.carol.uuid,
        },
        winner_id: users.carol.uuid,
      },
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_see_assumptions: true,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.carol,
  },
};

export const OwnerFinished: Story = {
  name: "Finished/Owner",
  args: {
    game: {
      ...game,
      status: "finished",
      scores: {
        [users.alice.uuid]: 7,
        [users.bob.uuid]: 8,
        [users.carol.uuid]: 10,
      },
      turn: null,
    } satisfies Game,
    permissions: {
      ...permissions,
      can_control_playback: false,
      can_advance_turn: false,
      can_start_game: false,
      can_start_turn: false,
      can_restart_game: true,
      can_see_assumptions: false,
      can_make_assumptions: false,
    } satisfies Permissions,
    user: users.alice,
  },
};

export const PlayerFinished: Story = {
  name: "Finished/Player",
  args: {
    game: {
      ...game,
      status: "finished",
      scores: {
        [users.alice.uuid]: 7,
        [users.bob.uuid]: 8,
        [users.carol.uuid]: 10,
      },
      turn: null,
    } satisfies Game,
    permissions,
    user: users.bob,
  },
};

export const ChallengerFinished: Story = {
  name: "Finished/Challenger",
  args: {
    game: {
      ...game,
      status: "finished",
      scores: {
        [users.alice.uuid]: 7,
        [users.bob.uuid]: 8,
        [users.carol.uuid]: 10,
      },
      turn: null,
    } satisfies Game,
    permissions,
    user: users.carol,
  },
};

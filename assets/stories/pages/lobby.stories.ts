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
};

export const PlayerLobby: Story = {
  name: "Lobby/Player",
  args: {
    permissions: {
      ...permissions,
      can_start_game: false,
    },
    user: users.bob,
  },
};

import { users } from "~fixtures/users";
import type { Meta, StoryObj } from "@storybook/svelte-vite";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room",
  component: Room,
  parameters: {
    inertia: {},
  },
  args: {
    roomId: "room-owner-lobby",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
} satisfies Meta<Props>;

export default meta;

type Story = StoryObj<Props>;

export const OwnerLobby: Story = {
  args: {
    roomId: "room-owner-lobby",
    qr: "<svg data-testid='room-qr'></svg>",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const PlayerLobby: Story = {
  args: {
    roomId: "room-player-lobby",
    scope: {
      user: users.bob,
      provider: null,
    },
  },
};

export const ReadyControls: Story = {
  args: {
    roomId: "room-ready-controls",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const MissingRoom: Story = {
  args: {
    roomId: "room-missing",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

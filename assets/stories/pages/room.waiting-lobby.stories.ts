import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { users } from "~fixtures/users";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room/Lobby",
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

type Story = StoryObj<typeof meta>;

export const Owner: Story = {
  args: {
    roomId: "room-owner-lobby",
    qr: "<svg data-testid='room-qr'></svg>",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const Player: Story = {
  args: {
    roomId: "room-player-lobby",
    scope: {
      user: users.bob,
      provider: null,
    },
  },
};

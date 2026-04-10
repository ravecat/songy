import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { users } from "~fixtures/users";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room/Scoreboard",
  component: Room,
  parameters: {
    inertia: {},
  },
  args: {
    roomId: "room-finished-restart",
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
    roomId: "room-finished-restart",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const Player: Story = {
  args: {
    roomId: "room-finished",
    scope: {
      user: users.carol,
      provider: null,
    },
  },
};

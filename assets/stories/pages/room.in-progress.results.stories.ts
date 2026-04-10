import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { users } from "~fixtures/users";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room/Turn/Results",
  component: Room,
  parameters: {
    inertia: {},
  },
  args: {
    roomId: "room-results-controls-bob",
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
    roomId: "room-results-controls-bob",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const ActivePlayer: Story = {
  args: {
    roomId: "room-results-controls-bob",
    scope: {
      user: users.bob,
      provider: null,
    },
  },
};

export const PassivePlayer: Story = {
  args: {
    roomId: "room-results",
    scope: {
      user: users.carol,
      provider: null,
    },
  },
};

export const NoWinner: Story = {
  args: {
    roomId: "room-results-no-winner",
    scope: {
      user: users.carol,
      provider: null,
    },
  },
};

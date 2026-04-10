import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { users } from "~fixtures/users";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room/Turn/Challenging",
  component: Room,
  parameters: {
    inertia: {},
  },
  args: {
    roomId: "room-challenging-controls-bob",
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
    roomId: "room-challenging-controls-bob",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

export const ActivePlayer: Story = {
  args: {
    roomId: "room-challenging-active-bob",
    scope: {
      user: users.bob,
      provider: null,
    },
  },
};

export const PassivePlayer: Story = {
  args: {
    roomId: "room-timeline-challenging-own",
    scope: {
      user: users.carol,
      provider: null,
    },
  },
};

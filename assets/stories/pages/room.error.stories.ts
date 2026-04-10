import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { users } from "~fixtures/users";

import Room from "~pages/room.svelte";
import type { Props } from "~pages/room.types";

const meta = {
  title: "Pages/Room/Error",
  component: Room,
  parameters: {
    inertia: {},
  },
  args: {
    roomId: "room-missing",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
} satisfies Meta<Props>;

export default meta;

type Story = StoryObj<typeof meta>;

export const MissingRoom: Story = {
  args: {
    roomId: "room-missing",
    scope: {
      user: users.alice,
      provider: null,
    },
  },
};

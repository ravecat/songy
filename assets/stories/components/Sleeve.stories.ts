import type { Meta, StoryObj } from "@storybook/svelte-vite";
import Sleeve from "~components/Sleeve.svelte";

const meta = {
  component: Sleeve,
  args: {
    track: {
      id: "storybook-default-track",
      title: "Midnight City",
      artist: "M83",
      year: 2011,
      meta: {},
    },
  },
} satisfies Meta<typeof Sleeve>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export const EmptyState: Story = {
  args: {
    track: null,
  },
};

export const LongMetadata: Story = {
  args: {
    track: {
      id: "storybook-long-track",
      title: "The Devil's Whispered Choir in the Neon Arcade",
      artist: "The Magnificent Broadcast Orchestra",
      year: 1987,
      meta: {},
    },
  },
};

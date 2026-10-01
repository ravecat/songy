import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect } from "storybook/test";
import Sleeve from "~components/sleeve.svelte";

const meta = {
  component: Sleeve,
  args: {
    track: {
      id: "storybook-default-track",
      title: "Midnight City",
      artist: "M83",
      year: 2011,
      cover_url: null,
      meta: {},
    },
  },
} satisfies Meta<typeof Sleeve>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {
  play: async ({ canvas }) => {
    await expect(canvas.getByText("Midnight City")).toBeVisible();
    await expect(canvas.getByText("M83")).toBeVisible();
    await expect(canvas.getByText("2011")).toBeVisible();
  },
};

export const EmptyState: Story = {
  args: {
    track: null,
  },
  play: async ({ canvas }) => {
    await expect(canvas.queryByText("Midnight City")).not.toBeInTheDocument();
    await expect(canvas.queryByText("M83")).not.toBeInTheDocument();
    await expect(canvas.queryByText("2011")).not.toBeInTheDocument();
    await expect(canvas.queryByRole("img")).not.toBeInTheDocument();
  },
};

export const LongMetadata: Story = {
  args: {
    track: {
      id: "storybook-long-track",
      title: "The Devil's Whispered Choir in the Neon Arcade",
      artist: "The Magnificent Broadcast Orchestra",
      year: 1987,
      cover_url: null,
      meta: {},
    },
  },
};

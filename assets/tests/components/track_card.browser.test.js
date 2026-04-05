import { createRawSnippet } from "svelte";
import { render } from "vitest-browser-svelte";
import { describe, expect, test } from "vitest";

import TrackCard from "~components/track_card.svelte";

describe("TrackCard", () => {
  const track = {
    title: "Test Song",
    artist: "Test Artist",
    year: 2023,
  };

  test("shows track information when revealed", async () => {
    const screen = render(TrackCard, { track, revealed: true });

    await expect.element(screen.getByText("Test Song")).toBeVisible();
    await expect.element(screen.getByText("Test Artist")).toBeVisible();
    await expect.element(screen.getByText("2023")).toBeVisible();
  });

  test("shows track information by default", async () => {
    const screen = render(TrackCard, { track });

    await expect.element(screen.getByText("Test Song")).toBeVisible();
    await expect.element(screen.getByText("Test Artist")).toBeVisible();
    await expect.element(screen.getByText("2023")).toBeVisible();
  });

  test("hides track information when not revealed", async () => {
    const screen = render(TrackCard, { track, revealed: false });

    await expect.element(screen.getByText("Test Song")).not.toBeInTheDocument();
    await expect.element(screen.getByText("Test Artist")).not.toBeInTheDocument();
    await expect.element(screen.getByText("2023")).not.toBeInTheDocument();
  });

  test("renders custom back content when not revealed", async () => {
    const screen = render(TrackCard, {
      track,
      revealed: false,
      back: createRawSnippet(() => ({
        render: () => "<span>Hidden side</span>",
      })),
    });

    await expect.element(screen.getByText("Hidden side")).toBeVisible();
  });

  test("hides back content when revealed", async () => {
    const screen = render(TrackCard, {
      track,
      revealed: true,
      back: createRawSnippet(() => ({
        render: () => "<span>Hidden side</span>",
      })),
    });

    await expect.element(screen.getByText("Hidden side")).not.toBeInTheDocument();
  });
});

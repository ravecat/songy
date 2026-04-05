import { render } from "vitest-browser-svelte";
import { describe, expect, test } from "vitest";

import Sleeve from "~components/sleeve.svelte";

describe("Sleeve", () => {
  const track = {
    id: "track-1",
    title: "Bohemian Rhapsody",
    artist: "Queen",
    year: 1975,
    cover_url: "https://example.com/cover.jpg",
    meta: {},
  };

  test("renders track artist, title, year, and cover", async () => {
    const screen = render(Sleeve, { track });

    await expect.element(screen.getByAltText("Bohemian Rhapsody")).toHaveAttribute(
      "src",
      "https://example.com/cover.jpg",
    );
    await expect.element(screen.getByText("Queen")).toBeVisible();
    await expect.element(screen.getByText("Bohemian Rhapsody")).toBeVisible();
    await expect.element(screen.getByText("1975")).toBeVisible();
  });

  test("does not render track details without track data", async () => {
    const screen = render(Sleeve);

    await expect.element(screen.getByText("Queen")).not.toBeInTheDocument();
    await expect.element(screen.getByText("Bohemian Rhapsody")).not.toBeInTheDocument();
    await expect.element(screen.getByText("1975")).not.toBeInTheDocument();
  });
});

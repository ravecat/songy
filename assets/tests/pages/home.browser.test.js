import Home from "~pages/home.svelte";
import { describe, expect, test } from "vitest";
import { render } from "../inertia";

function buildTrack(index) {
  return {
    id: `track-${index}`,
    title: `Track ${index}`,
    artist: `Artist ${index}`,
    year: 2000 + index,
    cover_url: `https://example.test/${index}.jpg`,
    meta: {},
  };
}

describe("Home", () => {
  test("mixes found tracks with placeholders into a 45-item cover grid", async () => {
    const tracks = Array.from({ length: 15 }, (_, index) => buildTrack(index + 1));

    render(Home, {
      props: {
        tracks,
      },
    });

    const covers = document.querySelectorAll(".cover-grid img");
    const placeholders = document.querySelectorAll(".cover-grid__item_placeholder");
    const renderedCoverUrls = [...covers].map((cover) => cover.getAttribute("src"));
    const expectedCoverUrls = tracks.map((track) => track.cover_url);

    expect(covers).toHaveLength(15);
    expect(placeholders).toHaveLength(30);
    expect(new Set(renderedCoverUrls)).toEqual(new Set(expectedCoverUrls));
  });
});

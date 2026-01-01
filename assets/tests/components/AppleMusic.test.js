import { render } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import * as GameContext from "~components/GameChannel.svelte";
import AppleMusic from "~components/AppleMusic.svelte";

describe("AppleMusic component", () => {
  let mockGameContext;
  let getGameContextSpy;

  beforeEach(() => {
    mockGameContext = {
      game: {
        track: {
          id: "1440783454",
          title: "Firestarter",
          artist: "The Prodigy",
          year: 1996,
          meta: {
            preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
          },
        },
      },
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  test("renders audio element", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AppleMusic);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("sets audio src from track preview_url", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AppleMusic);

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute(
      "src",
      "https://audio-ssl.itunes.apple.com/preview.m4a"
    );
  });

  test("renders without error when children snippet is provided", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    expect(() => {
      render(AppleMusic, {
        props: {
          children: () => {},
        },
      });
    }).not.toThrow();
  });

  test("handles missing preview_url gracefully", () => {
    mockGameContext.game.track.meta = {};

    getGameContextSpy.mockReturnValue(mockGameContext);

    const { container } = render(AppleMusic);

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });
});

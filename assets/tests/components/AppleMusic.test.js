import { render } from "@testing-library/svelte";
import { expect, test, describe, beforeEach } from "vitest";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import AppleMusic from "~components/AppleMusic.svelte";

describe("AppleMusic component", () => {
  let mockGameContext;

  beforeEach(() => {
    mockGameContext = {
      state: {
        turn: {
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
      },
    };
  });

  test("renders audio element", () => {
    const { container } = render(AppleMusic, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
  });

  test("sets audio src from track preview_url", () => {
    const { container } = render(AppleMusic, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    const audio = container.querySelector("audio");
    expect(audio).toHaveAttribute(
      "src",
      "https://audio-ssl.itunes.apple.com/preview.m4a"
    );
  });

  test("renders without error when children snippet is provided", () => {
    expect(() => {
      render(AppleMusic, {
        context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
        props: {
          children: () => {},
        },
      });
    }).not.toThrow();
  });

  test("handles missing preview_url gracefully", () => {
    mockGameContext.state.turn.track.meta = {};

    const { container } = render(AppleMusic, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    const audio = container.querySelector("audio");
    expect(audio).toBeInTheDocument();
    expect(audio.getAttribute("src")).toBeNull();
  });
});

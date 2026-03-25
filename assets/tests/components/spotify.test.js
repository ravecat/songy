import { render } from "@testing-library/svelte";
import { afterEach, beforeEach, expect, test, describe, vi } from "vitest";
import * as GameContext from "~/contexts/game";
import Spotify from "~components/spotify.svelte";
import SpotifyMock from "~mocks/spotify";

vi.stubGlobal("Spotify", SpotifyMock);

describe("Spotify", () => {
  let getProvider;
  let updateProvider;

  beforeEach(() => {
    getProvider = vi.fn().mockResolvedValue({ token: "test-token" });
    updateProvider = vi.fn().mockResolvedValue(undefined);

    vi.spyOn(GameContext, "getGameContext").mockReturnValue({
      getProvider,
      updateProvider,
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  test("initializes Spotify player when component mounts", () => {
    render(Spotify);

    window.onSpotifyWebPlaybackSDKReady();

    expect(window.Spotify.Player).toHaveBeenCalledWith({
      name: expect.any(String),
      getOAuthToken: expect.any(Function),
      volume: expect.any(Number),
    });
  });

  test("pushes get_provider event when getOAuthToken is invoked", () => {
    render(Spotify);

    window.onSpotifyWebPlaybackSDKReady();

    const player = window.Spotify.Player.mock.results[0].value;
    const getOAuthTokenCallback = player.options.getOAuthToken;
    const tokenCallback = vi.fn();

    getOAuthTokenCallback(tokenCallback);

    expect(getProvider).toHaveBeenCalled();
  });

  test("pushes update_provider event when player ready event is fired", () => {
    render(Spotify);

    window.onSpotifyWebPlaybackSDKReady();

    const player = window.Spotify.Player.mock.results[0].value;

    const [_, readyCb] = player.addListener.mock.calls.find(
      ([event]) => event === "ready"
    );

    readyCb({ device_id: "test-device-id" });

    expect(updateProvider).toHaveBeenCalledWith({
      device_id: "test-device-id",
    });
  });
});

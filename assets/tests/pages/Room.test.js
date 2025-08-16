import { render, screen } from "@testing-library/svelte";
import { afterEach, expect, test, vi } from "vitest";
import Room from "~pages/Room.svelte";
import Spotify from "~mocks/spotify";
import socket from "~/socket";

vi.stubGlobal("Spotify", Spotify);

vi.mock("~/socket", async () => {
  const { Socket } = await vi.importMock("phoenix");

  return {
    default: new Socket("/socket", {}),
  };
});

describe("Room", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  test("joins to channel with room id", () => {
    render(Room, { roomId: "test-room" });

    expect(socket.channel).toHaveBeenCalledWith("room:test-room", {});
  });

  test("listens state_updated event", () => {
    render(Room, { roomId: "test-room" });

    const channel = socket.channel.mock.results[0].value;

    expect(channel.on).toHaveBeenCalledWith(
      "state_updated",
      expect.any(Function)
    );
  });

  test.skip("should initialize Spotify player when component mounts", () => {
    render(Room, { roomId: "test-room" });

    window.onSpotifyWebPlaybackSDKReady();

    expect(window.Spotify.Player).toHaveBeenCalledWith({
      name: "Songy Player test-room",
      getOAuthToken: expect.any(Function),
      volume: 0.5,
    });
  });

  test("should call channel.push('get_spotify_token') when getOAuthToken is invoked", () => {
    render(Room, { roomId: "test-room" });

    const channel = socket.channel.mock.results[0].value;

    window.onSpotifyWebPlaybackSDKReady();

    const player = window.Spotify.Player.mock.results[0].value;
    const getOAuthTokenCallback = player.options.getOAuthToken;
    const tokenCallback = vi.fn();

    getOAuthTokenCallback(tokenCallback);

    expect(channel.push).toHaveBeenCalledWith("get_spotify_token", {});
  });

  test("should call channel.push('update_provider') when player ready event is fired", () => {
    render(Room, { roomId: "test-room" });

    const channel = socket.channel.mock.results[0].value;

    window.onSpotifyWebPlaybackSDKReady();

    const player = window.Spotify.Player.mock.results[0].value;

    const [_, readyCb] = player.addListener.mock.calls.find(
      ([event]) => event === "ready"
    );

    readyCb({ device_id: "test-device-id" });

    expect(channel.push).toHaveBeenCalledWith("update_provider", {
      device_id: "test-device-id",
    });
  });
});

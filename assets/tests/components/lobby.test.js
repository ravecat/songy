import { render, screen, fireEvent, within } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~/contexts/game";
import * as QrContext from "~components/qr_context.svelte";
import Lobby from "~components/lobby.svelte";

describe("Lobby", () => {
  let getGameContextSpy;
  let getQrContextSpy;

  const mockParticipants = {
    "user-1": {
      uuid: "user-1",
      name: "Alice",
      avatar_url: "https://example.com/alice.jpg",
    },
    "user-2": {
      uuid: "user-2",
      name: "Bob",
      avatar_url: "https://example.com/bob.jpg",
    },
    "user-3": {
      uuid: "user-3",
      name: "Charlie",
      avatar_url: "https://example.com/charlie.jpg",
    },
  };

  beforeEach(() => {
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
    getQrContextSpy = vi.spyOn(QrContext, "getQrContext");
    getQrContextSpy.mockReturnValue({ svg: "" });

    Object.assign(navigator, {
      clipboard: {
        writeText: vi.fn().mockResolvedValue(undefined),
      },
    });

    Object.defineProperty(window, "location", {
      value: { href: "https://example.com/game/abc123" },
      writable: true,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders lobby structure with players list and share button", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    expect(screen.getByRole("list")).toBeInTheDocument();
    expect(screen.getAllByRole("listitem")).toHaveLength(3);
    expect(screen.getByRole("button")).toBeInTheDocument();
  });

  test("displays all participants with avatars and names", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    expect(screen.getByAltText("Alice")).toBeInTheDocument();
    expect(screen.getByAltText("Bob")).toBeInTheDocument();
    expect(screen.getByAltText("Charlie")).toBeInTheDocument();

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
    expect(screen.getByText("Charlie")).toBeInTheDocument();
  });

  test("shows crown badge for room owner", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    const playersList = screen.getByRole("list");
    const players = within(playersList).getAllByRole("listitem");

    const ownerPlayer = players.find((player) =>
      within(player).queryByText("Alice"),
    );
    expect(ownerPlayer).toBeInTheDocument();

    const ownerBadge = within(ownerPlayer).getByRole("img", { hidden: true });
    expect(ownerBadge).toBeInTheDocument();
  });

  test("renders share button with URL", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    const shareButton = screen.getByRole("button");
    expect(shareButton).toBeInTheDocument();
    expect(
      within(shareButton).getByText(/example\.com\/game\/abc123/),
    ).toBeInTheDocument();
  });

  test("renders QR svg when context provides it", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    getQrContextSpy.mockReturnValue({
      svg: "<svg data-testid=\"qr-svg\"></svg>",
    });

    render(Lobby);

    expect(screen.getByTestId("qr-svg")).toBeInTheDocument();
  });

  test("copies URL to clipboard on share button click", async () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    const shareButton = screen.getByRole("button");
    await fireEvent.click(shareButton);

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
      "https://example.com/game/abc123",
    );
  });

  test("shows copied state after clicking share button", async () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: mockParticipants,
        queue: ["user-1", "user-2", "user-3"],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    const shareButton = screen.getByRole("button");
    await fireEvent.click(shareButton);

    expect(screen.getByText("Copied!")).toBeInTheDocument();
    expect(shareButton).toBeDisabled();
  });

  test("handles empty participants list", () => {
    getGameContextSpy.mockReturnValue({
      game: {
        participants: {},
        queue: [],
        owner_id: "user-1",
      },
    });

    render(Lobby);

    const playersList = screen.getByRole("list");
    expect(within(playersList).queryAllByRole("listitem")).toHaveLength(0);
  });

  test("handles missing game context gracefully", () => {
    getGameContextSpy.mockReturnValue({
      game: null,
    });

    render(Lobby);

    expect(screen.getByRole("list")).toBeInTheDocument();
    expect(screen.queryAllByRole("listitem")).toHaveLength(0);
    expect(screen.getByRole("button")).toBeInTheDocument();
  });
});

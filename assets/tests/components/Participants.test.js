import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import Participants from "~components/Participants.svelte";

describe("Participants", () => {
  const mockParticipants = [
    {
      uuid: "user-1",
      name: "Alice",
      avatar_url: "https://example.com/alice.jpg",
    },
    {
      uuid: "user-2",
      name: "Bob",
      avatar_url: "https://example.com/bob.jpg",
    },
    {
      uuid: "user-3",
      name: "Charlie",
      avatar_url: "https://example.com/charlie.jpg",
    },
  ];

  const mockChannelContext = {
    state: {
      participants: mockParticipants,
    },
  };

  const mockScopeContext = {
    user: {
      uuid: "user-2",
      name: "Bob",
    },
  };

  test("renders participants when participants list is not empty", () => {
    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
    expect(screen.getByText("Charlie")).toBeInTheDocument();
  });

  test("shows star indicator for current user's avatar", () => {
    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.getByLabelText("Your avatar")).toBeInTheDocument();
  });

  test("does not show star indicator when no current user", () => {
    const noUserScopeContext = {
      user: null,
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        ["scope", noUserScopeContext],
      ]),
    });

    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
  });

  test("shows star indicator only for matching user UUID", () => {
    const differentUserContext = {
      user: {
        uuid: "user-999", // Non-existent user
        name: "Different User",
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        ["scope", differentUserContext],
      ]),
    });

    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
  });

  test("renders nothing when participants list is empty", () => {
    const emptyChannelContext = {
      state: {
        participants: [],
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, emptyChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
    expect(screen.queryByText(/./)).not.toBeInTheDocument();
  });

  test("renders avatar images with correct alt text", () => {
    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        ["scope", mockScopeContext],
      ]),
    });

    const aliceAvatar = screen.getByAltText("Alice");
    const bobAvatar = screen.getByAltText("Bob");
    const charlieAvatar = screen.getByAltText("Charlie");

    expect(aliceAvatar).toBeInTheDocument();
    expect(bobAvatar).toBeInTheDocument();
    expect(charlieAvatar).toBeInTheDocument();

    expect(aliceAvatar).toHaveAttribute("src", "https://example.com/alice.jpg");
    expect(bobAvatar).toHaveAttribute("src", "https://example.com/bob.jpg");
    expect(charlieAvatar).toHaveAttribute(
      "src",
      "https://example.com/charlie.jpg"
    );
  });
});

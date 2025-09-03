import { render, screen } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import { SCOPE_CONTEXT_KEY } from "~components/Scope.svelte";
import Participants from "~components/Participants.svelte";

describe("Participants component", () => {
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
      scores: {
        "user-1": 42,
        "user-2": 15,
        "user-3": 88,
      },
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
        [SCOPE_CONTEXT_KEY, mockScopeContext],
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
        [SCOPE_CONTEXT_KEY, mockScopeContext],
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
        [SCOPE_CONTEXT_KEY, noUserScopeContext],
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
        [SCOPE_CONTEXT_KEY, differentUserContext],
      ]),
    });

    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
  });

  test("renders nothing when participants list is empty", () => {
    const emptyChannelContext = {
      state: {
        participants: [],
        scores: {},
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, emptyChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
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
        [SCOPE_CONTEXT_KEY, mockScopeContext],
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

  test("displays user scores in score indicators", () => {
    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, mockChannelContext],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("42")).toBeInTheDocument();
    expect(screen.getByText("15")).toBeInTheDocument();
    expect(screen.getByText("88")).toBeInTheDocument();
  });

  test("does not display score indicator when user has no score data", () => {
    const contextWithoutScores = {
      state: {
        participants: mockParticipants,
        scores: {},
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, contextWithoutScores],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.queryByText("0")).not.toBeInTheDocument();
  });

  test("does not display score indicator when scores field is missing", () => {
    const contextWithoutScoresField = {
      state: {
        participants: mockParticipants,
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, contextWithoutScoresField],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.queryByText("0")).not.toBeInTheDocument();
  });

  test("displays score indicator only for users who have score entries", () => {
    const contextWithPartialScores = {
      state: {
        participants: mockParticipants,
        scores: {
          "user-1": 25,
          "user-3": 0,
          // user-2 has no score entry
        },
      },
    };

    render(Participants, {
      context: new Map([
        [GAME_CONTEXT_KEY, contextWithPartialScores],
        [SCOPE_CONTEXT_KEY, mockScopeContext],
      ]),
    });

    expect(screen.getByText("25")).toBeInTheDocument();
    expect(screen.getByText("0")).toBeInTheDocument();
    expect(screen.getAllByText(/\d+/)).toHaveLength(2); // Only 2 score indicators shown
  });
});

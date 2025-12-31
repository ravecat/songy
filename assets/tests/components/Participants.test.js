import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi, afterEach } from "vitest";
import * as GameContext from "~components/GameChannel.svelte";
import * as Scope from "~components/Scope.svelte";
import Participants from "~components/Participants.svelte";

describe("Participants component", () => {
  let getScopeContextSpy;
  let getGameContextSpy;
  
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

  beforeEach(() => {
    getScopeContextSpy = vi.spyOn(Scope, 'getScopeContext');
    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test("renders participants when participants list is not empty", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);
    
    render(Participants);

    expect(screen.getByText("Alice")).toBeInTheDocument();
    expect(screen.getByText("Bob")).toBeInTheDocument();
    expect(screen.getByText("Charlie")).toBeInTheDocument();
  });

  test("shows star indicator for current user's avatar", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);
    
    render(Participants);

    expect(screen.getByLabelText("Your avatar")).toBeInTheDocument();
  });

  test("does not show star indicator when no current user", () => {
    const noUserScopeContext = {
      user: null,
    };
    
    getScopeContextSpy.mockReturnValue(noUserScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Participants);

    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
  });

  test("shows star indicator only for matching user UUID", () => {
    const differentUserContext = {
      user: {
        uuid: "user-999",
        name: "Different User",
      },
    };
    
    getScopeContextSpy.mockReturnValue(differentUserContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);

    render(Participants);

    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
  });

  test("renders nothing when participants list is empty", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    const emptyChannelContext = {
      state: {
        participants: [],
        scores: {},
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(emptyChannelContext);

    render(Participants);

    expect(screen.queryByRole("img")).not.toBeInTheDocument();
    expect(screen.queryByLabelText("Your avatar")).not.toBeInTheDocument();
    expect(screen.queryByText(/./)).not.toBeInTheDocument();
  });

  test("renders avatar images with correct alt text", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);
    
    render(Participants);

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
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(mockChannelContext);
    
    render(Participants);

    expect(screen.getByText("42")).toBeInTheDocument();
    expect(screen.getByText("15")).toBeInTheDocument();
    expect(screen.getByText("88")).toBeInTheDocument();
  });

  test("does not display score indicator when user has no score data", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    const contextWithoutScores = {
      state: {
        participants: mockParticipants,
        scores: {},
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(contextWithoutScores);

    render(Participants);

    expect(screen.queryByText("0")).not.toBeInTheDocument();
  });

  test("does not display score indicator when scores field is missing", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    const contextWithoutScoresField = {
      state: {
        participants: mockParticipants,
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(contextWithoutScoresField);

    render(Participants);

    expect(screen.queryByText("0")).not.toBeInTheDocument();
  });

  test("displays score indicator only for users who have score entries", () => {
    const mockScopeContext = {
      user: {
        uuid: "user-2",
        name: "Bob",
      },
    };
    
    const contextWithPartialScores = {
      state: {
        participants: mockParticipants,
        scores: {
          "user-1": 25,
          "user-3": 0,
        },
      },
    };
    
    getScopeContextSpy.mockReturnValue(mockScopeContext);
    getGameContextSpy.mockReturnValue(contextWithPartialScores);

    render(Participants);

    expect(screen.getByText("25")).toBeInTheDocument();
    expect(screen.getByText("0")).toBeInTheDocument();
    expect(screen.getAllByText(/\d+/)).toHaveLength(2);
  });
});

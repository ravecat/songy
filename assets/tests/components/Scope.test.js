import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import { Channel } from "phoenix";
import { GAME_CONTEXT_KEY } from "~components/GameContext.svelte";
import Scope from "~components/Scope.svelte";

vi.mock("phoenix");

describe("Scope", () => {
  let mockGameContext;

  beforeEach(() => {
    vi.clearAllMocks();

    mockGameContext = {
      channel: new Channel("room:123", {}, null),
    };
  });

  test("requests user data on mount", () => {
    render(Scope, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    expect(mockGameContext.channel.push).toHaveBeenCalledWith(
      "get_current_user",
      {}
    );
  });

  test("renders correctly during initialization", () => {
    render(Scope, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    expect(screen.getByLabelText("Loading")).toBeInTheDocument();
  });

  test("loads user data and updates context", async () => {
    const testUser = {
      uuid: "test-user-uuid",
      name: "Test User",
      avatar_url: "https://example.com/avatar.jpg",
    };

    mockGameContext.channel.push.mockReturnValue({
      receive: vi.fn().mockImplementation((status, callback) => {
        if (status === "ok") {
          callback(testUser);
        }
        return { receive: vi.fn() };
      }),
    });

    render(Scope, {
      context: new Map([[GAME_CONTEXT_KEY, mockGameContext]]),
    });

    expect(screen.queryByLabelText("Loading")).not.toBeInTheDocument();
  });
});

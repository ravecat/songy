import { render, screen } from "@testing-library/svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import { Channel } from "phoenix";
import * as GameContext from "~components/game_channel.svelte";
import Scope from "~components/scope.svelte";

vi.mock("phoenix");

describe("Scope", () => {
  let mockGameContext;
  let getGameContextSpy;

  beforeEach(() => {
    vi.clearAllMocks();

    mockGameContext = {
      channel: new Channel("room:123", {}, null),
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  test("requests user data on mount", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);

    expect(mockGameContext.channel.push).toHaveBeenCalledWith(
      "get_current_user",
      {}
    );
  });

  test("renders correctly during initialization", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);

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

    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);

    expect(screen.queryByLabelText("Loading")).not.toBeInTheDocument();
  });
});

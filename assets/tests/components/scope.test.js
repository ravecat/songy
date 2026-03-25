import { render, screen } from "@testing-library/svelte";
import { tick } from "svelte";
import { expect, test, describe, beforeEach, vi } from "vitest";
import * as GameContext from "~/contexts/game";
import Scope from "~components/scope.svelte";

describe("Scope", () => {
  let mockGameContext;
  let getGameContextSpy;
  let getCurrentUser;

  beforeEach(() => {
    vi.clearAllMocks();

    getCurrentUser = vi.fn().mockResolvedValue({
      uuid: "test-user-uuid",
      name: "Test User",
      avatar_url: "https://example.com/avatar.jpg",
    });

    mockGameContext = {
      getCurrentUser,
    };

    getGameContextSpy = vi.spyOn(GameContext, "getGameContext");
  });

  test("requests user data on mount", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);

    expect(getCurrentUser).toHaveBeenCalled();
  });

  test("renders correctly during initialization", () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);

    expect(screen.getByLabelText("Loading")).toBeInTheDocument();
  });

  test("loads user data and updates context", async () => {
    getGameContextSpy.mockReturnValue(mockGameContext);

    render(Scope);
    await Promise.resolve();
    await tick();

    expect(screen.queryByLabelText("Loading")).not.toBeInTheDocument();
  });
});

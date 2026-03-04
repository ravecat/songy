import { test, expect } from "~e2e/fixtures/test.fixture";

test.describe("room lobby", () => {
  test("owner creates room and sees lobby controls", async ({
    ownerLobbyPage,
  }) => {
    await expect(ownerLobbyPage.lobby.shareButton).toBeVisible();
    await expect(ownerLobbyPage.lobby.startGameButton).toBeVisible();
    await expect(ownerLobbyPage.lobby.startGameButton).toBeEnabled();
  });

  test("player joins room and cannot start game", async ({
    playerLobbyPage,
  }) => {
    await expect(playerLobbyPage.lobby.startGameButton).not.toBeVisible();
    await expect(playerLobbyPage.lobby.forwardButton).toBeVisible();
    await expect(playerLobbyPage.lobby.forwardButton).toBeDisabled();
  });

  test("all users can see each other in lobby", async ({
    ownerLobbyPage,
    playerLobbyPage,
  }) => {
    await expect(ownerLobbyPage.lobby.players).toHaveCount(2);
    await expect(playerLobbyPage.lobby.players).toHaveCount(2);

    await expect(
      ownerLobbyPage.lobby.participantsOnlineStatus,
    ).toHaveAccessibleName(/^2\s+players?\s+online$/i);
    await expect(
      playerLobbyPage.lobby.participantsOnlineStatus,
    ).toHaveAccessibleName(/^2\s+players?\s+online$/i);
  });

  test("participant copies share link to clipboard", async ({ ownerLobbyPage }) => {
    await ownerLobbyPage.page
      .context()
      .grantPermissions(["clipboard-read", "clipboard-write"]);

    await ownerLobbyPage.lobby.copyShareLink();
    await expect(ownerLobbyPage.lobby.shareButton).toBeDisabled();

    const clipboardValue = await ownerLobbyPage.page.evaluate(async () =>
      navigator.clipboard.readText(),
    );

    expect(clipboardValue).toBe(ownerLobbyPage.url);
  });
});

import { test, expect } from '~e2e/fixtures/test.fixture';

test.describe('room lobby', () => {
  test('owner creates room and sees lobby controls', async ({ ownerLobbyPage }) => {
    await expect(ownerLobbyPage.shareButton).toBeVisible();
    await expect(ownerLobbyPage.startGameButton).toBeVisible();
    await expect(ownerLobbyPage.startGameButton).toBeEnabled();
  });

  test('player joins room and cannot start game', async ({ playerLobbyPage }) => {
    await expect(playerLobbyPage.startGameButton).not.toBeVisible();
    await expect(playerLobbyPage.forwardButton).toBeVisible();
    await expect(playerLobbyPage.forwardButton).toBeDisabled();
  });
});

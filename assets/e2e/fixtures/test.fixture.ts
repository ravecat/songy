import { test as base } from '@playwright/test';
import { RoomPage } from '~e2e/pages/room.page';

export const test = base.extend<{
  ownerLobbyPage: RoomPage;
  playerLobbyPage: RoomPage;
}>({
  ownerLobbyPage: async ({ page }, use) => {
    const ownerRoom = new RoomPage(page);
    await ownerRoom.create();
    await use(ownerRoom);
  },
  playerLobbyPage: async ({ ownerLobbyPage, browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const player = new RoomPage(page);
    await player.goto(ownerLobbyPage.url);
    await use(player);
    await context.close();
  },
});

export { expect } from '@playwright/test';

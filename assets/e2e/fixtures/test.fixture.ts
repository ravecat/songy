import { test as base } from "@playwright/test";
import { HomePage } from "~e2e/pages/home.page";
import { RoomPage } from "~e2e/pages/room.page";

export const test = base.extend<{
  ownerLobbyPage: RoomPage;
  playerLobbyPage: RoomPage;
}>({
  ownerLobbyPage: async ({ page }, use) => {
    const home = new HomePage(page);
    await home.createRoom();
    await page.waitForURL(/\/[A-Z2-7]{4,}$/);
    const room = new RoomPage(page);
    await use(room);
  },
  playerLobbyPage: async ({ ownerLobbyPage, browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    const room = new RoomPage(page);
    await room.goto(ownerLobbyPage.url);
    await use(room);
    await context.close();
  },
});

export { expect } from "@playwright/test";

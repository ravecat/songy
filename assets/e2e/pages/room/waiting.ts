import type { Locator, Page } from "@playwright/test";

export class RoomWaiting {
  readonly title: Locator;
  readonly activePlayerAvatar: Locator;
  readonly readyButton: Locator;
  readonly forwardButton: Locator;

  constructor(readonly page: Page) {
    this.title = page.getByRole("heading", { level: 2 });
    this.activePlayerAvatar = page.getByRole("img");
    this.readyButton = page.getByRole("button", { name: "Ready" });
    this.forwardButton = page.getByRole("button", { name: "Forward" });
  }

  async startTurn(): Promise<void> {
    await this.readyButton.click();
  }

  async advanceTurn(): Promise<void> {
    await this.forwardButton.click();
  }
}

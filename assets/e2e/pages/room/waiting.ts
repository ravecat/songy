import type { Locator, Page } from "@playwright/test";

export class RoomWaiting {
  readonly section: Locator;
  readonly title: Locator;
  readonly activePlayerAvatar: Locator;
  readonly readyButton: Locator;
  readonly forwardButton: Locator;

  constructor(readonly page: Page) {
    this.section = page.getByRole("region", { name: "Turn waiting" });
    this.title = this.section.getByRole("heading", {
      level: 2,
      name: /it's your turn|.+ turn/i,
    });
    this.activePlayerAvatar = this.section.getByRole("img");
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

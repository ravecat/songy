import type { Locator, Page } from "@playwright/test";

export class RoomLobby {
  readonly shareButton: Locator;
  readonly startGameButton: Locator;
  readonly forwardButton: Locator;
  readonly participantAvatars: Locator;
  readonly participantsOnlineStatus: Locator;

  constructor(readonly page: Page) {
    this.shareButton = page.getByRole("button", {
      name: /copy share link/i,
    });
    this.startGameButton = page.getByRole("button", { name: "Start game" });
    this.forwardButton = page.getByRole("button", { name: "Forward" });
    this.participantsOnlineStatus = page.getByRole("status", {
      name: /\d+ players? online/i,
    });
    this.participantAvatars = this.participantsOnlineStatus.locator("img");
  }

  async startGame(): Promise<void> {
    await this.startGameButton.click();
  }

  async copyShareLink(): Promise<void> {
    await this.shareButton.click();
  }
}

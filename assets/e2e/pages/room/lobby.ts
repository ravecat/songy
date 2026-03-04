import type { Locator, Page } from "@playwright/test";

export class RoomLobby {
  readonly shareButton: Locator;
  readonly startGameButton: Locator;
  readonly forwardButton: Locator;
  readonly players: Locator;
  readonly participantsOnlineStatus: Locator;

  constructor(readonly page: Page) {
    this.shareButton = page.getByRole("button", {
      name: /copy share link/i,
    });
    this.startGameButton = page.getByRole("button", { name: "Start game" });
    this.forwardButton = page.getByRole("button", { name: "Forward" });
    this.players = page
      .getByRole("list", { name: "Lobby players" })
      .getByRole("listitem");
    this.participantsOnlineStatus = page.getByRole("status", {
      name: /\d+ players? online/i,
    });
  }

  async startGame(): Promise<void> {
    await this.startGameButton.click();
  }

  async copyShareLink(): Promise<void> {
    await this.shareButton.click();
  }
}

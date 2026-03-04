import type { Locator, Page } from "@playwright/test";

export class RoomResults {
  readonly challengers: Locator;
  readonly winner: Locator;
  readonly playAgainButton: Locator;

  constructor(readonly page: Page) {
    this.challengers = page
      .getByRole("list", { name: "Result challengers" })
      .getByRole("listitem");
    this.winner = this.challengers.locator('[aria-current="true"]');
    this.playAgainButton = page.getByRole("button", { name: "Play again" });
  }

  async playAgain(): Promise<void> {
    await this.playAgainButton.click();
  }
}

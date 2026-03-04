import type { Locator, Page } from "@playwright/test";

export class RoomChallenge {
  readonly timeline: Locator;
  readonly timelineCells: Locator;
  readonly forwardButton: Locator;

  constructor(readonly page: Page) {
    this.timeline = page.getByRole("list", { name: "Timeline" });
    this.timelineCells = this.timeline.getByRole("listitem");
    this.forwardButton = page.getByRole("button", { name: "Forward" });
  }

  async advanceTurn(): Promise<void> {
    await this.forwardButton.click();
  }
}

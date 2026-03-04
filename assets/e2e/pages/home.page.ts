import type { Locator, Page } from "@playwright/test";

export class HomePage {
  readonly quickGameButton: Locator;

  constructor(readonly page: Page) {
    this.quickGameButton = page.getByRole("button", { name: /quick game/i });
  }

  async goto(): Promise<void> {
    await this.page.goto("/");
  }

  async createRoom(): Promise<void> {
    await this.goto();
    await this.quickGameButton.click();
  }
}

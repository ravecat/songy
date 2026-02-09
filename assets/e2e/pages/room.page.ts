import { expect, type Locator, type Page } from '@playwright/test';

export class RoomPage {
  private static readonly ROOM_ID_PATTERN = /[A-Z2-7]{4,}/;

  readonly shareButton: Locator;
  readonly startGameButton: Locator;
  readonly forwardButton: Locator;
  readonly readyButton: Locator;

  private readonly quickGameButton: Locator;

  constructor(readonly page: Page) {
    this.shareButton = page.getByRole('button', { name: /copy share link/i });
    this.quickGameButton = page.getByRole('button', { name: /quick game/i });
    this.startGameButton = page.getByRole('button', { name: 'Start game' });
    this.forwardButton = page.getByRole('button', { name: 'Forward' });
    this.readyButton = page.getByRole('button', { name: 'Ready' });
  }

  get url(): string {
    return this.page.url();
  }

  get id(): string {
    const pathname = new URL(this.page.url()).pathname;
    const match = pathname.match(new RegExp(`^/(${RoomPage.ROOM_ID_PATTERN.source})$`));

    if (!match) {
      throw new Error(`No room ID in URL: ${this.page.url()}`);
    }

    return match[1];
  }

  async create(): Promise<void> {
    await this.page.goto('/');
    await this.quickGameButton.click();
    await expect(this.page).toHaveURL(new RegExp(`/${RoomPage.ROOM_ID_PATTERN.source}$`));
  }

  async goto(url: string): Promise<void> {
    await this.page.goto(url);
    await expect(this.page).toHaveURL(new RegExp(`/${RoomPage.ROOM_ID_PATTERN.source}$`));
  }

  async startGame(): Promise<void> {
    await this.startGameButton.click();
  }

  async startTurn(): Promise<void> {
    await this.readyButton.click();
  }
}

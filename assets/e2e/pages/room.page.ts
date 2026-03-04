import type { Page } from "@playwright/test";
import { RoomChallenge } from "~e2e/pages/room/challenge";
import { RoomLobby } from "~e2e/pages/room/lobby";
import { RoomResults } from "~e2e/pages/room/results";
import { RoomTurn } from "~e2e/pages/room/turn";
import { RoomWaiting } from "~e2e/pages/room/waiting";

export class RoomPage {
  private static readonly ROOM_ID_PATTERN = /[A-Z2-7]{4,}/;

  readonly lobby: RoomLobby;
  readonly waiting: RoomWaiting;
  readonly turn: RoomTurn;
  readonly challenge: RoomChallenge;
  readonly results: RoomResults;

  constructor(readonly page: Page) {
    this.lobby = new RoomLobby(page);
    this.waiting = new RoomWaiting(page);
    this.turn = new RoomTurn(page);
    this.challenge = new RoomChallenge(page);
    this.results = new RoomResults(page);
  }

  get url(): string {
    return this.page.url();
  }

  get id(): string {
    const pathname = new URL(this.page.url()).pathname;
    const match = pathname.match(
      new RegExp(`^/(${RoomPage.ROOM_ID_PATTERN.source})$`),
    );

    if (!match) {
      throw new Error(`No room ID in URL: ${this.page.url()}`);
    }

    return match[1];
  }

  async goto(url: string): Promise<void> {
    await this.page.goto(url);
  }
}

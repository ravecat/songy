import type { Locator, Page } from "@playwright/test";

type TimelineScrollOptions = {
  commit?: boolean;
};

export class RoomTurn {
  readonly timeline: Locator;
  readonly timelineCells: Locator;
  readonly playButton: Locator;
  readonly forwardButton: Locator;
  readonly readyButton: Locator;
  readonly swipeHint: Locator;

  constructor(readonly page: Page) {
    this.timeline = page.getByRole("list", { name: "Timeline" });
    this.timelineCells = this.timeline.getByRole("listitem");
    this.playButton = page.getByRole("button", {
      name: /play track|pause track/i,
    });
    this.forwardButton = page.getByRole("button", { name: "Forward" });
    this.readyButton = page.getByRole("button", { name: "Ready" });
    this.swipeHint = page.getByText(/swipe to place your guess/i);
  }

  async advanceTurn(): Promise<void> {
    await this.forwardButton.click();
  }

  async swipeTimeline(delta = 720): Promise<void> {
    await this.timeline.hover();
    await this.page.mouse.wheel(0, delta);
    await this.timeline.evaluate((timelineNode) => {
      timelineNode.dispatchEvent(new Event("scrollend", { bubbles: true }));
    });
  }

  async scrollTo(
    left: number,
    { commit = false }: TimelineScrollOptions = {},
  ): Promise<number> {
    return this.timeline.evaluate(
      (timelineNode, payload: { left: number; commit: boolean }) => {
        if (payload.commit) {
          timelineNode.dispatchEvent(
            new Event("pointerdown", { bubbles: true }),
          );
        }

        const maxLeft = Math.max(
          0,
          timelineNode.scrollWidth - timelineNode.clientWidth,
        );
        const targetLeft = Math.min(Math.max(payload.left, 0), maxLeft);

        timelineNode.scrollLeft = targetLeft;

        if (payload.commit) {
          timelineNode.dispatchEvent(new Event("scrollend", { bubbles: true }));
        }

        return timelineNode.scrollLeft;
      },
      { left, commit },
    );
  }

  async scrollBy(
    delta: number,
    { commit = false }: TimelineScrollOptions = {},
  ): Promise<number> {
    return this.timeline.evaluate(
      (timelineNode, payload: { delta: number; commit: boolean }) => {
        if (payload.commit) {
          timelineNode.dispatchEvent(
            new Event("pointerdown", { bubbles: true }),
          );
        }

        const maxLeft = Math.max(
          0,
          timelineNode.scrollWidth - timelineNode.clientWidth,
        );
        const targetLeft = Math.min(
          Math.max(timelineNode.scrollLeft + payload.delta, 0),
          maxLeft,
        );

        timelineNode.scrollLeft = targetLeft;

        if (payload.commit) {
          timelineNode.dispatchEvent(new Event("scrollend", { bubbles: true }));
        }

        return timelineNode.scrollLeft;
      },
      { delta, commit },
    );
  }

  async scrollToCell(index: number): Promise<void> {
    const scrolled = await this.timeline.evaluate(
      (timelineNode, targetIndex) => {
        const cells = Array.from(
          timelineNode.querySelectorAll<HTMLElement>("[role='listitem']"),
        );
        const target = cells[targetIndex];
        if (!target) return false;

        const targetCenter = target.offsetLeft + target.offsetWidth / 2;
        const viewportCenter = timelineNode.clientWidth / 2;
        const maxLeft = Math.max(
          0,
          timelineNode.scrollWidth - timelineNode.clientWidth,
        );
        const targetLeft = Math.min(
          Math.max(targetCenter - viewportCenter, 0),
          maxLeft,
        );

        timelineNode.dispatchEvent(new Event("pointerdown", { bubbles: true }));
        timelineNode.scrollLeft = targetLeft;
        timelineNode.dispatchEvent(new Event("scrollend", { bubbles: true }));

        return true;
      },
      index,
    );

    if (!scrolled) {
      throw new Error(`Timeline cell index is out of bounds: ${index}`);
    }
  }

  async scrollToPosition(position: number): Promise<void> {
    const scrolled = await this.timeline.evaluate(
      (timelineNode, targetPosition) => {
        const targets = Array.from(
          timelineNode.querySelectorAll<HTMLElement>(
            "[data-position][data-snap]",
          ),
        );
        const target = targets.find(
          (element) => Number(element.dataset.position) === targetPosition,
        );

        if (!target) return false;

        const targetCenter = target.offsetLeft + target.offsetWidth / 2;
        const viewportCenter = timelineNode.clientWidth / 2;
        const maxLeft = Math.max(
          0,
          timelineNode.scrollWidth - timelineNode.clientWidth,
        );
        const targetLeft = Math.min(
          Math.max(targetCenter - viewportCenter, 0),
          maxLeft,
        );

        timelineNode.dispatchEvent(new Event("pointerdown", { bubbles: true }));
        timelineNode.scrollLeft = targetLeft;
        timelineNode.dispatchEvent(new Event("scrollend", { bubbles: true }));

        return true;
      },
      position,
    );

    if (!scrolled) {
      throw new Error(`Timeline snap position is unavailable: ${position}`);
    }
  }

  async scrollLeft(): Promise<number> {
    return this.timeline.evaluate((timelineNode) => timelineNode.scrollLeft);
  }
}

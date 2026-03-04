import { test, expect } from "~e2e/fixtures/test.fixture";

test.describe("room active phase", () => {
  test.describe("owner policies", () => {
    test.beforeEach(async ({ ownerActivePage }) => {
      await expect(ownerActivePage.turn.timeline).toBeVisible();
    });

    test("shows timeline and swipe hint", async ({ ownerActivePage }) => {
      await expect(ownerActivePage.turn.timeline).toBeVisible();
      await expect(ownerActivePage.turn.swipeHint).toBeVisible();
    });

    test("can control playback", async ({ ownerActivePage }) => {
      await expect(ownerActivePage.turn.playButton).toBeVisible();
      await expect(ownerActivePage.turn.playButton).toBeEnabled();
    });

    test("cannot see ready button in ready phase", async ({
      ownerActivePage,
    }) => {
      await expect(ownerActivePage.turn.readyButton).not.toBeVisible();
    });

    test("starts with disabled forward button", async ({ ownerActivePage }) => {
      await expect(ownerActivePage.turn.forwardButton).toBeVisible();
      await expect(ownerActivePage.turn.forwardButton).toBeDisabled();
    });

    test("can swipe timeline", async ({ ownerActivePage }) => {
      const initialScroll = await ownerActivePage.turn.scrollLeft();
      await ownerActivePage.turn.swipeTimeline();

      await expect
        .poll(async () => ownerActivePage.turn.scrollLeft())
        .toBeGreaterThan(initialScroll);
    });

    test("enables forward button after swipe assumption", async ({
      ownerActivePage,
    }) => {
      await ownerActivePage.turn.swipeTimeline();
      await expect(ownerActivePage.turn.forwardButton).toBeEnabled();
    });
  });

  test.describe("player policies", () => {
    test.beforeEach(async ({ playerActivePage }) => {
      await expect(playerActivePage.turn.timeline).toBeVisible();
    });

    test("shows timeline and swipe hint", async ({ playerActivePage }) => {
      await expect(playerActivePage.turn.timeline).toBeVisible();
      await expect(playerActivePage.turn.swipeHint).toBeVisible();
    });

    test("cannot control playback", async ({ playerActivePage }) => {
      await expect(playerActivePage.turn.playButton).toBeVisible();
      await expect(playerActivePage.turn.playButton).toBeDisabled();
    });

    test("cannot see ready button in ready phase", async ({
      playerActivePage,
    }) => {
      await expect(playerActivePage.turn.readyButton).not.toBeVisible();
    });

    test("cannot advance turn", async ({ playerActivePage }) => {
      await expect(playerActivePage.turn.forwardButton).toBeVisible();
      await expect(playerActivePage.turn.forwardButton).toBeDisabled();
    });

    test("can swipe timeline", async ({ playerActivePage }) => {
      const initialScroll = await playerActivePage.turn.scrollLeft();
      await playerActivePage.turn.swipeTimeline();

      await expect
        .poll(async () => playerActivePage.turn.scrollLeft())
        .toBeGreaterThan(initialScroll);
    });

    test("cannot enable forward button after swipe", async ({
      playerActivePage,
    }) => {
      await playerActivePage.turn.swipeTimeline();
      await expect(playerActivePage.turn.forwardButton).toBeDisabled();
    });
  });
});

import { test, expect } from "~e2e/fixtures/test.fixture";

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

test.describe("room waiting", () => {
  test("participants transition from lobby to waiting stage", async ({
    ownerWaitingPage,
    playerWaitingPage,
  }) => {
    await expect(ownerWaitingPage.waiting.title).toBeVisible();
    await expect(ownerWaitingPage.waiting.activePlayerAvatar).toBeVisible();
    await expect(playerWaitingPage.waiting.title).toBeVisible();
    await expect(playerWaitingPage.waiting.activePlayerAvatar).toBeVisible();
  });

  test.describe("active participant", () => {
    test("can press ready", async ({ ownerWaitingPage }) => {
      await expect(ownerWaitingPage.waiting.readyButton).toBeVisible();
      await expect(ownerWaitingPage.waiting.readyButton).toBeEnabled();
      await expect(ownerWaitingPage.waiting.forwardButton).not.toBeVisible();
      await expect(ownerWaitingPage.waiting.title).toHaveAccessibleName(
        "It's your turn",
      );
    });

    test("sees own turn title and active avatar", async ({
      ownerWaitingPage,
    }) => {
      await expect(ownerWaitingPage.waiting.title).toBeVisible();
      const activePlayerName =
        (await ownerWaitingPage.waiting.activePlayerAvatar.getAttribute(
          "alt",
        )) ?? "";

      expect(activePlayerName).not.toBe("");
      await expect(ownerWaitingPage.waiting.title).toHaveAccessibleName(
        "It's your turn",
      );
      await expect(ownerWaitingPage.waiting.activePlayerAvatar).toHaveAttribute(
        "alt",
        activePlayerName,
      );
    });
  });

  test.describe("passive participant", () => {
    test("cannot advance turn", async ({ playerWaitingPage }) => {
      await expect(playerWaitingPage.waiting.forwardButton).toBeVisible();
      await expect(playerWaitingPage.waiting.readyButton).not.toBeVisible();
      await expect(playerWaitingPage.waiting.forwardButton).toBeDisabled();
      await expect(playerWaitingPage.waiting.title).toBeVisible();
      await expect(playerWaitingPage.waiting.title).not.toHaveAccessibleName(
        "It's your turn",
      );
    });

    test("sees active participant turn and avatar", async ({
      ownerWaitingPage,
      playerWaitingPage,
    }) => {
      await expect(playerWaitingPage.waiting.forwardButton).toBeVisible();
      const activePlayerName =
        (await ownerWaitingPage.waiting.activePlayerAvatar.getAttribute(
          "alt",
        )) ?? "";

      expect(activePlayerName).not.toBe("");
      await expect(playerWaitingPage.waiting.title).toHaveAccessibleName(
        new RegExp(`^${escapeRegExp(activePlayerName)}\\s+turn$`, "i"),
      );
      await expect(
        playerWaitingPage.waiting.activePlayerAvatar,
      ).toHaveAttribute("alt", activePlayerName);
    });
  });
});

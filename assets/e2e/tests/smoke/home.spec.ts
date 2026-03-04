import { HomePage } from "~e2e/pages/home.page";
import { test, expect } from "~e2e/fixtures/test.fixture";

test.describe("home", () => {
  test("loads and has quick game button", async ({ page }) => {
    await page.goto("/");

    await expect(page).toHaveTitle(/Songy/);
    await expect(
      page.getByRole("button", { name: /quick game/i }),
    ).toBeVisible();
  });

  test("quick game redirects to room", async ({ page }) => {
    const home = new HomePage(page);

    await home.createRoom();
    await expect(page).toHaveURL(/\/[A-Z2-7]{4,}$/);
  });
});

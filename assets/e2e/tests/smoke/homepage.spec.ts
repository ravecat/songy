import { test, expect } from '~e2e/fixtures/test.fixture';

test('homepage loads and has correct title', async ({ page }) => {
  await page.goto('/');

  await expect(page).toHaveTitle(/Songy/);
  await expect(page.getByRole('button', { name: /quick game/i })).toBeVisible();
});


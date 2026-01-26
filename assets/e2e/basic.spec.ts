import { test, expect } from '@playwright/test';

test('homepage loads and has correct title', async ({ page }) => {
  await page.goto('/');
  
  await expect(page).toHaveTitle(/Songy/);
  
  const heading = page.locator('h1, h2, .logo, [role="heading"]');
  const count = await heading.count();
  expect(count).toBeGreaterThan(0);
});

test('page loads without console errors', async ({ page }) => {
  const errors: string[] = [];
  page.on('pageerror', (error) => {
    errors.push(error.message);
  });
  
  await page.goto('/');
  
  expect(errors).toHaveLength(0);
});

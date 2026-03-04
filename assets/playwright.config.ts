import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.BASE_URL || "http://localhost:4001";
const port = new URL(baseURL).port || "4001";
const vitePort = process.env.VITE_PORT || "5174";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: "html",
  use: {
    baseURL,
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: `MIX_ENV=e2e PHX_SERVER=true PORT=${port} VITE_PORT=${vitePort} mix phx.server`,
    url: baseURL,
    reuseExistingServer: true,
    timeout: 120000,
    cwd: "..",
  },
});

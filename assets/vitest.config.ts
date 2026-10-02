/// <reference types="vitest" />
import { storybookTest } from "@storybook/addon-vitest/vitest-plugin";
import { playwright } from "@vitest/browser-playwright";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, mergeConfig } from "vitest/config";
import viteConfig from "./vite.config";

const dirname = path.dirname(fileURLToPath(import.meta.url));
const contextOptions = {
  viewport: { width: 1280, height: 900 },
  screen: { width: 1280, height: 900 },
  deviceScaleFactor: 1,
  locale: "en-US",
  timezoneId: "UTC",
};

export default mergeConfig(
  viteConfig,
  defineConfig({
    server: { port: 0, strictPort: false },
    resolve: {
      conditions: ["svelte", "browser", "import", "default"],
    },
    test: {
      globals: true,
      exclude: ["node_modules", "dist"],
      attachmentsDir: path.join(".vitest", "attachments"),
      outputFile: {
        html: path.join(dirname, ".vitest/report/index.html"),
      },
      coverage: {
        provider: "v8",
        reporter: ["text", "json", "html", "clover", "lcov"],
        reportsDirectory: "./coverage",
      },
      browser: {
        api: { strictPort: false },
        provider: playwright({
          contextOptions,
        }),
      },
      projects: [
        {
          extends: true,
          test: {
            name: "unit",
            environment: "jsdom",
            include: ["tests/**/*.{test,spec}.{js,ts}"],
            exclude: ["tests/**/*.browser.{test,spec}.{js,ts}"],
          },
        },
        {
          extends: true,
          test: {
            name: "browser",
            include: ["tests/**/*.browser.{test,spec}.{js,ts}"],
            setupFiles: ["vitest-browser-svelte", "./tests/setup.browser.ts"],
            browser: {
              enabled: true,
              headless: true,
              instances: [{ browser: "chromium" }],
            },
          },
        },
        {
          extends: true,
          optimizeDeps: { exclude: ["@storybook/svelte"] },
          plugins: [
            storybookTest({
              configDir: path.join(dirname, ".storybook"),
            }),
            {
              name: "visual-project-cache",
              enforce: "post",
              config: () => ({
                cacheDir: path.join(dirname, ".vitest/cache/visual"),
              }),
            },
          ],
          test: {
            name: "visual",
            fileParallelism: false,
            sequence: { groupOrder: 1 },
            setupFiles: [path.join(dirname, ".storybook/vitest.setup.ts")],
            browser: {
              enabled: true,
              headless: true,
              screenshotFailures: true,
              provider: playwright({
                contextOptions: {
                  ...contextOptions,
                  reducedMotion: "reduce",
                },
              }),
              instances: (["light", "dark"] as const).flatMap((theme) =>
                (["desktop", "tablet", "mobile"] as const).map((viewport) => ({
                  browser: "chromium",
                  name: `visual-${theme}-${viewport}`,
                  screenshotDirectory: path.join(
                    ".vitest/screenshots",
                    theme,
                    viewport,
                  ),
                  provide: {
                    visualGlobals: { theme, viewport: { value: viewport } },
                  },
                })),
              ),
              trace: {
                // Shared instances cannot finalize concurrent trace chunks; use one instance for diagnostics.
                mode: "off",
                tracesDir: path.join(dirname, ".vitest/traces"),
              },
              expect: {
                toMatchScreenshot: {
                  comparatorOptions: {
                    allowedMismatchedPixels: 30,
                  },
                  resolveDiffPath: ({
                    arg,
                    attachmentsDir,
                    browserName,
                    ext,
                    root: projectRoot,
                    screenshotDirectory,
                    testFileDirectory,
                    testFileName,
                  }) => {
                    return path.join(
                      projectRoot,
                      attachmentsDir,
                      testFileDirectory,
                      testFileName,
                      path.basename(path.dirname(screenshotDirectory)),
                      path.basename(screenshotDirectory),
                      browserName,
                      `${arg}${ext}`,
                    );
                  },
                  resolveScreenshotPath: ({
                    arg,
                    browserName,
                    ext,
                    root: projectRoot,
                    screenshotDirectory,
                    testFileDirectory,
                    testFileName,
                  }) => {
                    return path.join(
                      projectRoot,
                      "__screenshots__",
                      testFileDirectory,
                      testFileName,
                      path.basename(path.dirname(screenshotDirectory)),
                      path.basename(screenshotDirectory),
                      browserName,
                      `${arg}${ext}`,
                    );
                  },
                },
              },
            },
          },
        },
      ],
    },
  }),
);

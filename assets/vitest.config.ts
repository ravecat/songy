/// <reference types="vitest" />
import { storybookTest } from '@storybook/addon-vitest/vitest-plugin';
import { playwright } from '@vitest/browser-playwright';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

const dirname = path.dirname(fileURLToPath(import.meta.url));

export default mergeConfig(
  viteConfig,
  defineConfig({
    resolve: {
      conditions: ['svelte', 'browser', 'import', 'default'],
    },
    test: {
      globals: true,
      exclude: ['node_modules', 'dist'],
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html', 'clover', 'lcov'],
        reportsDirectory: './coverage',
      },
      projects: [
        {
          extends: true,
          test: {
            name: 'unit',
            environment: 'jsdom',
            setupFiles: ['./tests/setup.js'],
            include: ['tests/**/*.{test,spec}.{js,ts}'],
            exclude: ['tests/**/*.browser.{test,spec}.{js,ts}'],
          },
        },
        {
          extends: true,
          test: {
            name: 'browser',
            include: ['tests/**/*.browser.{test,spec}.{js,ts}'],
            setupFiles: ['vitest-browser-svelte'],
            browser: {
              enabled: true,
              headless: true,
              provider: playwright(),
              instances: [{ browser: 'chromium' }],
            },
          },
        },
        {
          extends: true,
          plugins: [
            storybookTest({
              configDir: path.join(dirname, '.storybook'),
            }),
          ],
          test: {
            name: 'storybook',
            browser: {
              enabled: true,
              headless: true,
              provider: playwright(),
              instances: [{ browser: 'chromium' }],
            },
          },
        },
      ],
    },
  })
);

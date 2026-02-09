/// <reference types="vitest" />
import { playwright } from '@vitest/browser-playwright';
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';
import path from 'path';

export default mergeConfig(
  viteConfig,
  defineConfig({
    resolve: {
      conditions: ['svelte', 'browser', 'import', 'default'],
      alias: {
        'phoenix': path.resolve(__dirname, '__mocks__/phoenix.js'),
      },
    },
    test: {
      globals: true,
      exclude: ['node_modules', 'dist'],
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
            include: ['tests/browser/**/*.browser.{test,spec}.{js,ts}'],
            setupFiles: ['./tests/setup.browser.ts'],
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

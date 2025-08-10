/// <reference types="vitest" />
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';
import path from 'path';

export default mergeConfig(
  viteConfig,
  defineConfig({
    resolve: {
      conditions: ['browser'],
      alias: {
        // Add only test-specific mock alias
        'phoenix': path.resolve(__dirname, '__mocks__/phoenix.js'),
      },
    },
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./tests/setup.js'],
      include: ['tests/**/*.{test,spec}.{js,ts}'],
      exclude: ['node_modules', 'dist'],
    },
  })
);

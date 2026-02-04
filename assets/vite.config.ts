import { defineConfig, searchForWorkspaceRoot } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import { svelte, vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import { visualizer } from 'rollup-plugin-visualizer';
import esToolkit from 'vite-plugin-es-toolkit';
import path from 'path';

const port = parseInt(process.env.VITE_PORT || '5173', 10);

export default defineConfig({
  server: {
    port: port,
    host: true,
    cors: true,
    allowedHosts: true,
    strictPort: true,
    fs: {
      allow: [
        searchForWorkspaceRoot(process.cwd()),
        path.resolve(__dirname, '../priv/authorization'),
      ],
    },
  },
  resolve: {
    conditions: ['svelte', 'browser', 'import', 'default'],
    alias: {
      '~': path.resolve(__dirname, 'js'),
      '~hooks': path.resolve(__dirname, 'js/hooks'),
      '~pages': path.resolve(__dirname, 'js/pages'),
      '~shared': path.resolve(__dirname, 'js/shared'),
      '~types': path.resolve(__dirname, 'js/shared/types'),
      '~mocks': path.resolve(__dirname, '__mocks__'),
      '~components': path.resolve(__dirname, 'js/components'),
      '~icons': path.resolve(__dirname, 'icons'),
      '~priv': path.resolve(__dirname, '../priv'),
    },
  },
  build: {
    target: 'esnext',
    manifest: true,
    rollupOptions: {
      input: ['js/app.js', 'css/app.css'],
      output: {
        manualChunks: {
          vendor: ['phoenix', 'phoenix_html'],
          framework: ['svelte', '@inertiajs/core', '@inertiajs/svelte', 'axios'],
        },
      },
    },
    outDir: '../priv/static',
    emptyOutDir: true,
  },
  plugins: [
    esToolkit(),
    tailwindcss(),
    svelte({
      preprocess: [vitePreprocess()],
      compilerOptions: {
        modernAst: true,
      },
    }),
    visualizer({ gzipSize: true }),
  ],
});

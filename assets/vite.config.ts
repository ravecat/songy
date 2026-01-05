import { defineConfig, searchForWorkspaceRoot } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import { svelte, vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: ['http://localhost:4000', 'http://127.0.0.1:4000'] },
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
    },
    outDir: '../priv/static',
    emptyOutDir: true,
  },
  plugins: [
    tailwindcss(),
    svelte({
      preprocess: [vitePreprocess()],
      compilerOptions: {
        modernAst: true,
      },
    }),
  ],
});

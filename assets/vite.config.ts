import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import { svelte, vitePreprocess } from '@sveltejs/vite-plugin-svelte';
import path from 'path';

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: 'http://127.0.0.1:4000' },
  },
  resolve: {
    conditions: ['svelte', 'browser', 'import', 'default'],
    alias: {
      '@': path.resolve(__dirname, 'js'),
      '@hooks': path.resolve(__dirname, 'js/hooks'),
      '@pages': path.resolve(__dirname, 'js/pages'),
      '@shared': path.resolve(__dirname, 'js/shared'),
      '@types': path.resolve(__dirname, 'js/shared/types'),
      '@mocks': path.resolve(__dirname, '__mocks__'),
      '@components': path.resolve(__dirname, 'js/components'),
    },
  },
  build: {
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

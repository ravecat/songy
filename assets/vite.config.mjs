/// <reference types="vitest" />

import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import { svelte, vitePreprocess } from "@sveltejs/vite-plugin-svelte";
import path from "path";

export default defineConfig(({ command }) => {
  const isDev = command !== "build";
  
  return {
    server: {
      port: 5173,
      strictPort: true,
      cors: { origin: "http://127.0.0.1:4000" },
    },
    resolve: {
      conditions: ["svelte", "browser", "import", "default"],
      alias: {
        "@": path.resolve(__dirname, "js"),
        "@hooks": path.resolve(__dirname, "js/hooks"),
        "@pages": path.resolve(__dirname, "js/pages"),
        "@mocks": path.resolve(__dirname, "__mocks__"),
      },
    },
    build: {
      manifest: true,
      sourcemap: isDev,
      rollupOptions: {
        input: ["js/app.js", "css/app.css"],
      },
      outDir: "../priv/static",
      emptyOutDir: true,
    },
    plugins: [
      tailwindcss(),
      svelte({
        preprocess: [vitePreprocess()],
        compilerOptions: {
          modernAst: true,
          hmr: true,
          dev: command !== "build",
        },
      }),
    ],
    test: {
      globals: true,
      environment: "jsdom",
      setupFiles: ["./tests/setup.js"],
      include: ["tests/**/*.{test,spec}.{js,ts}"],
      exclude: ["node_modules", "dist"],
      passWithNoTests: true,
      deps: {
        moduleDirectories: ['node_modules', '.'],
      }
    },
  };
});

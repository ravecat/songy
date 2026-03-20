import path from "node:path";
import { fileURLToPath } from "node:url";
import tailwindcss from "@tailwindcss/vite";
import { svelte, vitePreprocess } from "@sveltejs/vite-plugin-svelte";
import { visualizer } from "rollup-plugin-visualizer";
import esToolkit from "vite-plugin-es-toolkit";
import { searchForWorkspaceRoot, type UserConfig } from "vite";

const assetsDir = fileURLToPath(new URL(".", import.meta.url));
const projectRoot = path.resolve(assetsDir, "..");

export default {
  server: {
    port: parseInt(process.env.VITE_PORT || "5173", 10),
    host: true,
    cors: true,
    allowedHosts: true,
    strictPort: true,
    fs: {
      allow: [
        searchForWorkspaceRoot(assetsDir),
        projectRoot,
        path.resolve(projectRoot, "priv/authorization"),
      ],
    },
  },
  resolve: {
    conditions: ["svelte", "browser", "import", "default"],
    alias: {
      axios: path.resolve(assetsDir, "js/lib/axios-shim.js"),
      "~": path.resolve(assetsDir, "js"),
      "~hooks": path.resolve(assetsDir, "js/hooks"),
      "~pages": path.resolve(assetsDir, "js/pages"),
      "~shared": path.resolve(assetsDir, "js/shared"),
      "~types": path.resolve(assetsDir, "js/shared/types"),
      "~mocks": path.resolve(assetsDir, "__mocks__"),
      "~components": path.resolve(assetsDir, "js/components"),
      "~icons": path.resolve(assetsDir, "icons"),
      "~priv": path.resolve(projectRoot, "priv"),
    },
  },
  optimizeDeps: {
    exclude: ["axios"],
  },
  build: {
    target: "esnext",
    manifest: true,
    rollupOptions: {
      input: ["js/app.js", "css/app.css"],
      output: {
        manualChunks: {
          vendor: ["phoenix", "phoenix_html"],
          framework: ["svelte", "@inertiajs/core", "@inertiajs/svelte"],
        },
      },
    },
    outDir: "../priv/static",
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
} satisfies UserConfig;

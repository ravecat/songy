import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/vite-plugin-svelte').SvelteConfig} */
const config = {
  // Enable preprocessing for TypeScript and other languages
  preprocess: vitePreprocess()
};

export default config;

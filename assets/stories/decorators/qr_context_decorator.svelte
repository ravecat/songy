<script lang="ts">
  import type { Snippet } from "svelte";
  import QrContext from "~components/qr_context.svelte";

  interface Props {
    children?: Snippet;
    svg?: string;
  }

  const defaultSvg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="180" height="180">
      <rect width="180" height="180" rx="24" fill="#ffffff" />
      <rect x="18" y="18" width="42" height="42" rx="8" fill="#111111" />
      <rect x="30" y="30" width="18" height="18" rx="3" fill="#ffffff" />
      <rect x="120" y="18" width="42" height="42" rx="8" fill="#111111" />
      <rect x="132" y="30" width="18" height="18" rx="3" fill="#ffffff" />
      <rect x="18" y="120" width="42" height="42" rx="8" fill="#111111" />
      <rect x="30" y="132" width="18" height="18" rx="3" fill="#ffffff" />
      <path d="M82 24h18v18H82zm18 18h18v18h-18zm-18 18h18v18H82zm36 18h18v18h-18zM82 96h18v18H82zm18 18h18v18h-18zm18 18h18v18h-18zM82 132h18v18H82z" fill="#111111" />
    </svg>
  `;

  let { children, svg = defaultSvg }: Props = $props();
</script>

<QrContext svg={svg}>
  {@render children?.()}
</QrContext>

<script lang="ts">
  import { usePage } from "@inertiajs/svelte";
  import { Link, Copy, Check } from "lucide-svelte";
  import Sleeve from "~components/sleeve.svelte";
  import type { Props } from "~pages/room.types";

  const page = usePage<Props>();
  let { qr = "" } = $derived($page.props);

  let copied = $state(false);

  async function copyShareLink() {
    await navigator.clipboard.writeText(window.location.href);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }
</script>

<div class="lobby">
  <div class="lobby__record">
    <div class="lobby__sleeve-frame">
      <Sleeve />
      {#if qr}
        <div class="lobby__qr">
          {@html qr}
        </div>
      {/if}
    </div>
  </div>

  <button
    class="lobby-share"
    class:lobby-share_copied={copied}
    onclick={copyShareLink}
    disabled={copied}
    aria-label="Copy share link"
  >
    <span
      class="lobby-share__content"
      class:lobby-share__content_hidden={copied}
    >
      <Link size={16} />
      <span class="lobby-share__url">{window.location.href}</span>
      <Copy size={16} class="lobby-share__copy-icon" />
    </span>
    <span
      class="lobby-share__content lobby-share__content_overlay"
      class:lobby-share__content_hidden={!copied}
    >
      <Check size={20} />
      <span>Copied!</span>
    </span>
  </button>
</div>

<style>
  .lobby {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1.5rem;
    box-sizing: border-box;
    width: 100%;
    padding: 1.5rem;
    min-height: 100%;
  }

  .lobby__record {
    --record-sleeve-size: clamp(9.5rem, 56vw, 13.75rem);
    position: relative;
    inline-size: var(--record-sleeve-size);
    block-size: var(--record-sleeve-size);
    margin-inline: auto;
  }

  .lobby__sleeve-frame {
    --sleeve-size: var(--record-sleeve-size);
    position: relative;
    z-index: var(--z-above);
    inline-size: var(--record-sleeve-size);
    block-size: var(--record-sleeve-size);
  }

  .lobby__qr {
    position: absolute;
    inset: clamp(0.75rem, 4vw, 1rem);
    z-index: var(--z-modal);
    padding: clamp(0.375rem, 2vw, 0.5rem);
    background: var(--color-white);
    border-radius: var(--radius-md);
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
  }

  @media (max-width: 639px) {
    .lobby-share {
      inline-size: 17rem;
    }
  }

  .lobby-share {
    position: relative;
    display: flex;
    justify-content: center;
    max-inline-size: 100%;
    padding: 0.875rem 1.5rem;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: var(--radius-md);
    color: white;
    font-weight: var(--font-weight-semibold);
    cursor: pointer;
    transition: all var(--transition-fast);
    backdrop-filter: blur(8px);
  }

  .lobby-share__content {
    display: flex;
    align-items: center;
    justify-content: center;
    min-width: 0;
    gap: 0.75rem;
    transition: opacity var(--transition-fast);
  }

  .lobby-share__content_overlay {
    position: absolute;
    inset: 0;
  }

  .lobby-share__content_hidden {
    opacity: 0;
    pointer-events: none;
  }

  .lobby-share:hover {
    background: rgba(255, 255, 255, 0.15);
    border-color: rgba(255, 255, 255, 0.3);
  }

  .lobby-share:active {
    transform: scale(0.98);
  }

  .lobby-share_copied {
    cursor: default;
    pointer-events: none;
  }

  .lobby-share__url {
    flex: 1 1 auto;
    min-width: 0;
    font-family: monospace;
    font-size: 0.875rem;
    opacity: var(--opacity-emphasis);
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .lobby-share :global(.lobby-share__copy-icon) {
    opacity: var(--opacity-muted);
  }
</style>

<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { getQrContext } from "~components/QrContext.svelte";
  import { Link, Copy, Check, Crown } from "lucide-svelte";
  import Vinyl from "~components/Vinyl.svelte";
  import Sleeve from "~components/Sleeve.svelte";

  const { game } = $derived.by(getGameContext);
  const { svg: qrSvg } = $derived.by(getQrContext);

  const participants = $derived(game?.participants ?? {});
  const queue = $derived(game?.queue ?? []);
  const ownerId = $derived(game?.owner_id ?? "");

  let copied = $state(false);

  async function copyShareLink() {
    await navigator.clipboard.writeText(window.location.href);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }
</script>

<div class="lobby">
  <div class="lobby__players" role="list">
    {#each queue as uuid, i (uuid)}
      {@const participant = participants[uuid]}
      {#if participant}
        <div
          class="lobby-player"
          class:lobby-player_owner={uuid === ownerId}
          style="--index: {i}"
          role="listitem"
        >
          <div class="lobby-player__frame">
            <img
              src={participant.avatar_url}
              alt={participant.name}
              class="lobby-player__avatar"
            />
            {#if uuid === ownerId}
              <div class="lobby-player__badge">
                <Crown size={16} strokeWidth={2.5} />
              </div>
            {/if}
          </div>
          <span class="lobby-player__name">{participant.name}</span>
        </div>
      {/if}
    {/each}
  </div>

  <div class="lobby__record">
    <div class="lobby__vinyl">
      <Vinyl />
    </div>
    <Sleeve />
    {#if qrSvg}
      <div class="lobby__qr">
        {@html qrSvg}
      </div>
    {/if}
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
    padding: 1.5rem;
    height: 100%;
  }

  .lobby__players {
    display: flex;
    justify-content: center;
    align-items: flex-start;
    gap: var(--spacing-md);
    flex-wrap: wrap;
  }

  .lobby-player {
    display: flex;
    flex-direction: column;
    align-items: center;
    max-width: 5rem;
    animation: avatar-pop 0.4s var(--ease-bounce) backwards;
    animation-delay: calc(var(--index) * 0.08s);
  }

  .lobby-player__frame {
    position: relative;
    padding: var(--spacing-xs);
    border: var(--border-thick) solid var(--color-white-emphasis);
    border-radius: var(--radius-sm);
    box-shadow: var(--shadow-base);
  }

  .lobby-player_owner .lobby-player__frame {
    border-color: var(--color-gold);
    box-shadow: var(--shadow-gold-glow), var(--shadow-base);
  }

  .lobby-player__avatar {
    display: block;
    width: 3.5rem;
    height: 3.5rem;
    border-radius: var(--radius-sm);
    object-fit: cover;
  }

  .lobby-player__badge {
    position: absolute;
    bottom: 0;
    right: 0;
    width: 1.25rem;
    height: 1.25rem;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: var(--radius-sm);
    background: var(--gradient-gold);
    color: var(--color-white);
  }

  .lobby-player__name {
    width: 100%;
    margin-top: var(--spacing-sm);
    font-size: var(--font-size-xs);
    font-weight: var(--font-weight-medium);
    color: var(--color-white-emphasis);
    text-align: center;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  @keyframes avatar-pop {
    from {
      opacity: 0;
      transform: scale(0.5);
    }
  }

  .lobby__record {
    --sleeve-size: 180px;
    --vinyl-size: 164px;
    position: relative;
    display: flex;
    align-items: center;
  }

  .lobby__vinyl {
    position: absolute;
    left: calc(var(--sleeve-size) * 0.5);
    width: var(--vinyl-size);
    height: var(--vinyl-size);
    z-index: var(--z-base);
  }

  .lobby__record :global(.sleeve) {
    position: relative;
    z-index: var(--z-above);
  }

  .lobby__qr {
    position: absolute;
    inset: 1rem;
    z-index: var(--z-modal);
    padding: 0.5rem;
    background: var(--color-white);
    border-radius: var(--radius-md);
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
  }

  .lobby__qr :global(svg) {
    display: block;
    width: 100%;
    height: 100%;
  }

  .lobby__qr :global(svg path) {
    fill: var(--color-text);
  }

  @media (min-width: 640px) {
    .lobby__record {
      --sleeve-size: 220px;
      --vinyl-size: 200px;
    }
  }

  @media (max-width: 639px) {
    .lobby-player__avatar {
      width: 2.5rem;
      height: 2.5rem;
    }

    .lobby__players {
      gap: var(--spacing-sm);
    }
  }

  .lobby-share {
    position: relative;
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
    font-family: monospace;
    font-size: 0.875rem;
    opacity: var(--opacity-emphasis);
    max-width: 230px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .lobby-share :global(.lobby-share__copy-icon) {
    opacity: var(--opacity-muted);
  }
</style>

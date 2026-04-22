<script module>
  export { default as layout } from "~/layout.svelte";
</script>

<script>
  import { inertia, Deferred } from "@inertiajs/svelte";

  let { tracks } = $props();

  const coverGridSize = 45;
</script>

<h1 class="sr-only">Songy - Music Game</h1>

<div class="landing">
  <div class="landing__covers">
    <Deferred data="tracks">
      {#snippet fallback()}
        <div class="cover-grid">
          {#each Array(coverGridSize) as _}
            <div class="cover-grid__item cover-grid__item_placeholder"></div>
          {/each}
        </div>
      {/snippet}
      <div class="cover-grid">
        {#each Array.isArray(tracks) ? tracks : [] as track, i (track.id)}
          <img
            src={track.cover_url}
            alt="{track.artist} - {track.title}"
            class="cover-grid__item"
            style="--i: {i}"
          />
        {/each}
      </div>
    </Deferred>
  </div>

  <div class="actions">
    <div class="hero">
      <p class="hero__tagline">The Music Guessing Game</p>
      <h2 class="hero__title">
        Feel the <span class="hero__words">
          <span class="hero__word">music</span>
          <span class="hero__word">vibes</span>
          <span class="hero__word">beats</span>
        </span>?
      </h2>
      <p class="hero__description">Challenge friends. Rank tracks. Win.</p>
      <form use:inertia={{ href: "/create", method: "post" }}>
        <button type="submit" class="btn btn-quick-start w-3xs">
          Quick game
        </button>
      </form>
    </div>
  </div>
</div>

<style>
  .landing {
    height: 100%;
    display: flex;
    flex-direction: row;
    overflow: hidden;
  }

  .landing__covers {
    flex: 1 1 45%;
    max-width: var(--breakpoint-mobile);
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0.75rem;
    height: 100%;
    background: var(--landing-gradient);
  }

  .cover-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    width: 100%;
    max-width: min(100%, 800px);
    height: 100%;
    align-content: center;
    overflow: visible;
  }

  .cover-grid__item {
    aspect-ratio: 1 / 1;
    width: 100%;
    object-fit: cover;
    border-radius: var(--radius-lg);
    box-shadow: 0 4px 12px rgb(0 0 0 / 0.25);
    opacity: 0;
    animation: fade-in 0.4s ease calc(sin(var(--i) * 1.618) * 0.4s + 0.4s)
      forwards;
    transition:
      transform 0.2s ease,
      box-shadow 0.2s ease;
  }

  .cover-grid__item:hover {
    transform: scale(1.08);
    box-shadow: 0 8px 24px rgb(0 0 0 / 0.35);
    opacity: var(--opacity-full);
    z-index: 1;
  }

  .cover-grid__item_placeholder {
    aspect-ratio: 1 / 1;
    width: 100%;
    border-radius: var(--radius-lg);
    box-shadow: 0 4px 12px rgb(0 0 0 / 0.25);
    background: rgb(255 255 255 / 0.15);
    animation: pulse 1.5s ease-in-out infinite;
    opacity: 1;
  }

  .actions {
    flex: 2 1 55%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem 1.5rem;
    background-color: var(--color-base-100);
  }

  .hero {
    text-align: center;
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
    align-items: center;
    max-width: 400px;
  }

  .hero__tagline {
    font-size: 0.75rem;
    font-weight: 600;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    color: var(--color-primary);
    margin: 0;
  }

  .hero__title {
    font-size: clamp(1.75rem, 5vw, 2.5rem);
    font-weight: 700;
    line-height: 1.15;
    margin: 0;
    color: var(--color-base-content);
  }

  .hero__words {
    display: inline-flex;
    flex-direction: column;
    height: 1.15em;
    overflow: hidden;
    vertical-align: bottom;
  }

  .hero__word {
    height: 1.15em;
    line-height: 1.15;
    animation: word-rotate 4s ease-in-out infinite;
  }

  @keyframes word-rotate {
    0%,
    20% {
      transform: translateY(0);
    }
    33%,
    53% {
      transform: translateY(-100%);
    }
    66%,
    86% {
      transform: translateY(-200%);
    }
    100% {
      transform: translateY(-300%);
    }
  }

  .hero__description {
    font-size: 0.9rem;
    color: var(--color-base-content);
    opacity: 0.7;
    margin: 0;
    line-height: 1.5;
  }

  .btn-quick-start {
    background: linear-gradient(135deg, #ec4899, #8b5cf6, #06b6d4);
    color: white;
    border: none;
    box-shadow: 0 4px 20px rgb(139 92 246 / 0.4);
  }

  .btn-quick-start:hover {
    background: linear-gradient(135deg, #db2777, #7c3aed, #0891b2);
    box-shadow: 0 6px 28px rgb(139 92 246 / 0.5);
  }

  @media (max-width: 640px) {
    .landing {
      position: relative;
    }

    .landing__covers {
      position: absolute;
      inset: 0;
      flex: none;
      width: 100%;
      height: 100%;
      padding: 0.5rem;
    }

    .actions {
      position: relative;
      z-index: 1;
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1rem;
      background: transparent;
    }

    .landing__covers::after {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(
        circle at center,
        transparent 20%,
        rgb(0 0 0 / 0.7)
      );
      pointer-events: none;
    }

    .hero {
      background: rgb(0 0 0 / 0.3);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border-radius: 0;
      padding: 2rem 1.5rem;
      border: none;
      border-top: 1px solid rgb(255 255 255 / 0.1);
      border-bottom: 1px solid rgb(255 255 255 / 0.1);
    }

    .hero__tagline,
    .hero__title,
    .hero__description {
      color: var(--color-neutral-content);
    }
  }
</style>

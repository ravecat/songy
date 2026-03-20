<script lang="ts">
  import type { Track } from "~shared/types/track";

  interface Props {
    track?: Track | null;
  }

  let { track }: Props = $props();
</script>

<div class="sleeve">
  {#if track?.cover_url}
    <img
      src={track.cover_url}
      alt={track.title}
      class="sleeve__cover-img"
    />
    <div class="sleeve__overlay"></div>
  {:else}
    <svg class="sleeve__pattern" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid slice">
      <rect width="100" height="100" fill="#2e3440" />
      <!-- Diagonal stripes with varying thickness - retro vinyl style -->
      <polygon points="-5,0 15,0 -5,20" fill="#d08770" opacity="0.7" />
      <polygon points="25,0 55,0 -5,60 -5,30" fill="#bf616a" opacity="0.7" />
      <polygon points="65,0 90,0 -5,95 -5,70" fill="#5e81ac" opacity="0.7" />
      <polygon points="100,0 100,15 10,105 -5,105 -5,100" fill="#88c0d0" opacity="0.7" />
      <polygon points="100,25 100,50 35,115 15,115" fill="#a3be8c" opacity="0.7" />
      <polygon points="100,60 100,80 60,120 45,120" fill="#ebcb8b" opacity="0.7" />
      <polygon points="100,90 100,105 85,120 75,120" fill="#b48ead" opacity="0.7" />
    </svg>
  {/if}
  {#if track}
    <div class="sleeve__info">
      <div class="sleeve__artist">{track.artist}</div>
      <div class="sleeve__title">{track.title}</div>
    </div>
    <div class="sleeve__year">{track.year ?? ""}</div>
  {/if}
</div>

<style>
  .sleeve {
    display: grid;
    width: var(--sleeve-size, 220px);
    height: var(--sleeve-size, 220px);
    border-radius: var(--radius-md);
    box-shadow:
      var(--shadow-glass),
      var(--shadow-inner);
    overflow: hidden;
  }

  .sleeve > * {
    grid-area: 1 / 1;
  }

  .sleeve__cover-img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .sleeve__overlay {
    background: rgba(0, 0, 0, 0.35);
  }

  .sleeve__info {
    align-self: start;
    justify-self: start;
    padding: 1rem;
    max-width: 130px;
  }

  .sleeve__year {
    align-self: end;
    justify-self: start;
    padding: 1rem;
    font-size: 2rem;
    font-weight: var(--font-weight-extrabold);
    background: linear-gradient(135deg, #facc15, #f97316);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1;
  }

  .sleeve__artist {
    font-size: 1rem;
    font-weight: var(--font-weight-semibold);
    color: rgba(255, 255, 255, 0.9);
    line-height: 1.2;
  }

  .sleeve__title {
    font-size: 0.875rem;
    font-style: italic;
    color: rgba(255, 255, 255, 0.6);
    margin-top: 0.25rem;
    line-height: 1.3;
  }

  .sleeve__pattern {
    width: 100%;
    height: 100%;
  }
</style>

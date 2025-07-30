<script>
  import { getScopeContext } from "@shared/context/scope";
  import { getChannelContext } from "@shared/context/channel.js";

  const { state } = $derived.by(getChannelContext);
  const { user } = $derived.by(getScopeContext);

  let userTimeline = $derived(state?.timelines?.[user?.uuid] || []);
</script>

<div class="timeline">
  {#each userTimeline as track, index (track.title + track.artist + track.year)}
    <div class="track-card" style="animation-delay: {index * 100}ms">
      <div class="artist-text">
        {#if track.artist.length > 12}
          <div class="marquee">
            <div>{track.artist}</div>
            <div>{track.artist}</div>
          </div>
        {:else}
          <div class="text-overflow-container">{track.artist}</div>
        {/if}
      </div>
      <div class="year-container">
        <span class="year-text">
          {track.year}
        </span>
      </div>
      <div class="title-text">
        {#if track.title.length > 12}
          <div class="marquee">
            <div>{track.title}</div>
            <div>{track.title}</div>
          </div>
        {:else}
          <div class="text-overflow-container">{track.title}</div>
        {/if}
      </div>
    </div>
  {/each}
</div>

<style>
  .timeline {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
  }

  .track-card {
    position: relative;
    overflow: hidden;
    width: 8rem;
    height: 8rem;
    background: linear-gradient(135deg, #facc15, #f97316);
    border-radius: 0.5rem;
    box-shadow:
      0 10px 15px -3px rgba(0, 0, 0, 0.1),
      0 4px 6px -2px rgba(0, 0, 0, 0.05);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 0 0.5rem;
    animation: scaleIn 400ms ease-out forwards;
    transform: scale(0);
  }

  .artist-text {
    color: #1f2937;
    font-weight: 600;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
  }

  .year-container {
    margin-bottom: 0.5rem;
  }

  .year-text {
    font-size: 2.25rem;
    font-weight: 700;
    color: #000000;
    line-height: 1;
    letter-spacing: 0.025em;
    display: inline-block;
  }

  .title-text {
    font-size: 0.875rem;
    font-style: italic;
    color: #1f2937;
  }

  @keyframes scaleIn {
    0% {
      transform: scale(0);
      opacity: 0;
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }

  .text-overflow-container {
    white-space: nowrap;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .marquee {
    display: flex;
    overflow: hidden;
    white-space: nowrap;
    user-select: none;
    width: 100%;
  }

  .marquee > div {
    animation: marquee 8s linear infinite;
    padding-right: 20px;
    flex-shrink: 0;
  }

  .marquee:hover > div {
    animation-play-state: paused;
  }

  @keyframes marquee {
    from {
      transform: translateX(100%);
    }

    to {
      transform: translateX(-100%);
    }
  }
</style>

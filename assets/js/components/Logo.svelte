<script>
  let { loading = true, children } = $props();
</script>

{#if loading}
  <div class="flex flex-col items-center">
    <div class="audio-bars" role="status" aria-label="Loading">
      <div class="bar" data-letter="S"></div>
      <div class="bar" data-letter="O"></div>
      <div class="bar" data-letter="N"></div>
      <div class="bar" data-letter="G"></div>
      <div class="bar" data-letter="Y"></div>
    </div>
  </div>
{:else if children}
  {@render children?.()}
{/if}

<style>
  .audio-bars {
    display: flex;
    gap: 3px;
    align-items: end;
    height: 40px;
  }

  .bar {
    width: 8px;
    background: white;
    opacity: 0.7;
    animation: bounce 2s infinite ease-in-out;
    position: relative;
  }

  .bar::after {
    content: attr(data-letter);
    position: absolute;
    bottom: -20px;
    left: 50%;
    transform: translateX(-50%);
    color: white;
    font-size: 12px;
    font-weight: bold;
    opacity: 0.8;
  }

  .bar:nth-child(1) {
    animation-delay: 0.2s;
    animation-duration: 1.05s;
  }
  .bar:nth-child(2) {
    animation-delay: 0.4s;
    animation-duration: 1.35s;
  }
  .bar:nth-child(3) {
    animation-delay: 0.1s;
    animation-duration: 1.2s;
  }
  .bar:nth-child(4) {
    animation-delay: 0.5s;
    animation-duration: 0.9s;
  }
  .bar:nth-child(5) {
    animation-delay: 0.3s;
    animation-duration: 1.15s;
  }

  @keyframes bounce {
    0%,
    80%,
    100% {
      height: 8px;
    }
    40% {
      height: 40px;
    }
  }
</style>

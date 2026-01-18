<script>
  let { size = 56, class: className = "", ...restProps } = $props();
</script>

<svg
  class={className}
  width={size}
  height={size}
  viewBox="0 0 56 65"
  preserveAspectRatio="xMidYMid meet"
  role="status"
  aria-label="loading"
  {...restProps}
>
  <rect
    class="bar bar-1"
    x="2"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 6px 48px"
  />
  <text class="letter letter-1" x="6" y="59">S</text>

  <rect
    class="bar bar-2"
    x="13"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 17px 48px"
  />
  <text class="letter letter-2" x="17" y="59">O</text>

  <rect
    class="bar bar-3"
    x="24"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 28px 48px"
  />
  <text class="letter letter-3" x="28" y="59">N</text>

  <rect
    class="bar bar-4"
    x="35"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 39px 48px"
  />
  <text class="letter letter-4" x="39" y="59">G</text>

  <rect
    class="bar bar-5"
    x="46"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 50px 48px"
  />
  <text class="letter letter-5" x="50" y="59">Y</text>
</svg>

<style>
  .bar {
    fill: white;
    opacity: 0.7;
    animation: bounce 2s infinite ease-in-out;
  }

  .letter {
    fill: white;
    font-size: 12px;
    font-weight: bold;
    opacity: 0.8;
    text-anchor: middle;
  }

  .bar-1,
  .letter-1 {
    animation-delay: 0.2s;
    animation-duration: 1.05s;
  }
  .bar-2,
  .letter-2 {
    animation-delay: 0.4s;
    animation-duration: 1.35s;
  }
  .bar-3,
  .letter-3 {
    animation-delay: 0.1s;
    animation-duration: 1.2s;
  }
  .bar-4,
  .letter-4 {
    animation-delay: 0.5s;
    animation-duration: 0.9s;
  }
  .bar-5,
  .letter-5 {
    animation-delay: 0.3s;
    animation-duration: 1.15s;
  }

  @keyframes bounce {
    0%,
    80%,
    100% {
      transform: scaleY(1);
    }
    40% {
      transform: scaleY(5);
    }
  }
</style>

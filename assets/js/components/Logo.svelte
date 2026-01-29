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
    class="logo__bar logo__bar_1"
    x="2"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 6px 48px"
  />
  <text class="logo__letter logo__letter_1" x="6" y="59">S</text>

  <rect
    class="logo__bar logo__bar_2"
    x="13"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 17px 48px"
  />
  <text class="logo__letter logo__letter_2" x="17" y="59">O</text>

  <rect
    class="logo__bar logo__bar_3"
    x="24"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 28px 48px"
  />
  <text class="logo__letter logo__letter_3" x="28" y="59">N</text>

  <rect
    class="logo__bar logo__bar_4"
    x="35"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 39px 48px"
  />
  <text class="logo__letter logo__letter_4" x="39" y="59">G</text>

  <rect
    class="logo__bar logo__bar_5"
    x="46"
    y="40"
    width="8"
    height="8"
    style="transform-origin: 50px 48px"
  />
  <text class="logo__letter logo__letter_5" x="50" y="59">Y</text>
</svg>

<style>
  .logo__bar {
    fill: white;
    opacity: var(--opacity-medium);
    animation: bounce 2s infinite ease-in-out;
  }

  .logo__letter {
    fill: white;
    font-size: 12px;
    font-weight: var(--font-weight-bold);
    opacity: var(--opacity-emphasis);
    text-anchor: middle;
  }

  .logo__bar_1,
  .logo__letter_1 {
    animation-delay: var(--delay-base);
    animation-duration: 1.05s;
  }
  .logo__bar_2,
  .logo__letter_2 {
    animation-delay: var(--delay-lg);
    animation-duration: 1.35s;
  }
  .logo__bar_3,
  .logo__letter_3 {
    animation-delay: var(--delay-sm);
    animation-duration: 1.2s;
  }
  .logo__bar_4,
  .logo__letter_4 {
    animation-delay: var(--delay-xl);
    animation-duration: 0.9s;
  }
  .logo__bar_5,
  .logo__letter_5 {
    animation-delay: var(--delay-md);
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

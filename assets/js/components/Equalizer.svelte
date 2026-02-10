<script>
  let { size = 56, class: className = "", ...restProps } = $props();
</script>

<svg
  class={className}
  width={size}
  height={size}
  viewBox="0 0 56 48"
  preserveAspectRatio="xMidYMid meet"
  role="status"
  aria-label="loading"
  {...restProps}
>
  <rect class="eq__bar eq__bar_1" x="2" y="40" width="8" height="8" style="transform-origin: 6px 48px" />
  <rect class="eq__bar eq__bar_2" x="13" y="40" width="8" height="8" style="transform-origin: 17px 48px" />
  <rect class="eq__bar eq__bar_3" x="24" y="40" width="8" height="8" style="transform-origin: 28px 48px" />
  <rect class="eq__bar eq__bar_4" x="35" y="40" width="8" height="8" style="transform-origin: 39px 48px" />
  <rect class="eq__bar eq__bar_5" x="46" y="40" width="8" height="8" style="transform-origin: 50px 48px" />
</svg>

<style>
  .eq__bar {
    fill: white;
    opacity: var(--opacity-medium);
    animation: bounce 2s infinite ease-in-out;
  }

  .eq__bar_1 { animation-delay: var(--delay-base); animation-duration: 1.05s; }
  .eq__bar_2 { animation-delay: var(--delay-lg);   animation-duration: 1.35s; }
  .eq__bar_3 { animation-delay: var(--delay-sm);   animation-duration: 1.2s; }
  .eq__bar_4 { animation-delay: var(--delay-xl);   animation-duration: 0.9s; }
  .eq__bar_5 { animation-delay: var(--delay-md);   animation-duration: 1.15s; }

  @keyframes bounce {
    0%, 80%, 100% { transform: scaleY(1); }
    40% { transform: scaleY(5); }
  }
</style>

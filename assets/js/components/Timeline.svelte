<script>
  import { dndzone } from "svelte-dnd-action";
  import { flip } from "svelte/animate";

  let {
    items = [],
    flipDurationMs = 150,
    onConsider,
    onFinalize,
    type = "timeline",
    children,
    ...props
  } = $props();

  function defaultHandleConsider(e) {
    items = e.detail.items;
  }

  function defaultHandleFinalize(e) {
    items = e.detail.items;
  }

  const handleConsider = onConsider || defaultHandleConsider;
  const handleFinalize = onFinalize || defaultHandleFinalize;
</script>

<div
  class="timeline"
  use:dndzone={{
    items,
    flipDurationMs,
    type,
    ...props,
  }}
  onconsider={handleConsider}
  onfinalize={handleFinalize}
>
  {#each items as item (item.id)}
    <div animate:flip={{ duration: flipDurationMs }}>
      {@render children?.(item)}
    </div>
  {/each}
</div>

<style>
  .timeline {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
    padding: 1rem;
  }
</style>

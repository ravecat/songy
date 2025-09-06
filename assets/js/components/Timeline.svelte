<script lang="ts" generics="TimelineItem extends { id: any }">
  import { dragHandleZone } from "svelte-dnd-action";
  import type { DndEvent, Options, DndZoneAttributes } from "svelte-dnd-action";
  import { flip } from "svelte/animate";
  import type { Snippet } from "svelte";

  interface TimelineProps<T extends { id: any }>
    extends Options<T>,
      DndZoneAttributes<T> {
    children?: Snippet<[T]>;
  }

  let {
    items = [] as TimelineItem[],
    flipDurationMs = 150,
    onconsider,
    onfinalize,
    type = "timeline",
    children,
    ...props
  }: TimelineProps<TimelineItem> = $props();

  function defaultHandleConsider(e: CustomEvent<DndEvent<TimelineItem>>) {
    items = e.detail.items;
  }

  function defaultHandleFinalize(e: CustomEvent<DndEvent<TimelineItem>>) {
    items = e.detail.items;
  }

  const handleConsider = onconsider || defaultHandleConsider;
  const handleFinalize = onfinalize || defaultHandleFinalize;
</script>

<div
  class="timeline"
  use:dragHandleZone={{
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

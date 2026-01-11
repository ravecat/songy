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

  const handleConsider = (event: CustomEvent<DndEvent<TimelineItem>>) => {
    (onconsider ?? defaultHandleConsider)(event);
  };

  const handleFinalize = (event: CustomEvent<DndEvent<TimelineItem>>) => {
    (onfinalize ?? defaultHandleFinalize)(event);
  };
</script>

<div
  class="flex min-h-0 flex-1 flex-wrap items-center justify-center gap-4 content-center p-4"
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

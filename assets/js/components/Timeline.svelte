<script lang="ts" generics="TimelineItem extends { id: any, current?: boolean }">
  import { dragHandleZone } from "svelte-dnd-action";
  import type { DndEvent, Options, DndZoneAttributes } from "svelte-dnd-action";
  import { flip } from "svelte/animate";
  import type { Snippet } from "svelte";
  import { tick } from "svelte";
  import { onMount, onDestroy } from "svelte";

  interface TimelineProps<T extends { id: any, current?: boolean }>
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

  let scrollContainer: HTMLDivElement;
  let isInitialized = false;
  let centerTimeout: number | null = null;

  // Центрирование текущего элемента
  async function centerCurrentItem(maxAttempts = 3) {
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      await tick();
      await new Promise(resolve => requestAnimationFrame(resolve as unknown as FrameRequestCallback));

      if (!scrollContainer || !isInitialized) {
        await new Promise(resolve => setTimeout(resolve as unknown as FrameRequestCallback, 100));
        continue;
      }

      const currentIndex = items.findIndex((item) => item.current);
      if (currentIndex === -1) return;

      const elements = scrollContainer.querySelectorAll('.timeline-item-wrapper');
      const element = elements[currentIndex] as HTMLDivElement;
      if (!element || element.offsetWidth === 0) {
        await new Promise(resolve => setTimeout(resolve as unknown as FrameRequestCallback, 100));
        continue;
      }

      const containerWidth = scrollContainer.clientWidth;
      const elementWidth = element.offsetWidth;

      if (containerWidth === 0) {
        await new Promise(resolve => setTimeout(resolve as unknown as FrameRequestCallback, 100));
        continue;
      }

      // Центрируем элемент
      const targetScrollLeft = element.offsetLeft - containerWidth / 2 + elementWidth / 2;

      scrollContainer.scrollTo({
        left: targetScrollLeft,
        behavior: 'smooth',
      });

      return;
    }
  }

  $effect(() => {
    if (!isInitialized) return;
    centerCurrentItem();
  });

  onMount(async () => {
    await tick();
    await new Promise(resolve => setTimeout(resolve as unknown as FrameRequestCallback, 50));
    await new Promise(resolve => requestAnimationFrame(resolve as unknown as FrameRequestCallback));
    isInitialized = true;
    centerCurrentItem();
  });

  onDestroy(() => {
    if (centerTimeout !== null) {
      clearTimeout(centerTimeout);
    }
  });
</script>

<div
  bind:this={scrollContainer}
  class="flex min-h-0 flex-1 items-center gap-4 p-4 overflow-x-auto overflow-y-hidden scroll-smooth"
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
    <div class="timeline-item-wrapper" animate:flip={{ duration: flipDurationMs }}>
      {@render children?.(item)}
    </div>
  {/each}
</div>

<style>
  .timeline-item-wrapper {
    flex: 0 0 auto;
  }
</style>

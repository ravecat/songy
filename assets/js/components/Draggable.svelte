<script lang="ts">
  import { dragHandle } from "svelte-dnd-action";
  import type { Snippet } from "svelte";

  interface DraggableProps {
    /** Whether the content should be draggable */
    draggable?: boolean;
    /** Children content to wrap */
    children?: Snippet;
  }

  let { draggable = true, children }: DraggableProps = $props();
</script>

{#if draggable}
  <div use:dragHandle>
    {@render children?.()}
  </div>
{:else}
  {@render children?.()}
{/if}

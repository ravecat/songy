<script>
  let { children } = $props();
</script>

<div class="page-background">
  {@render children?.()}
</div>

<style>
  .page-background {
    background: var(--room-gradient);
  }
</style>

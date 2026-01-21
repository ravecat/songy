<script>
  let { children } = $props();
</script>

<div class="page-background">
  {@render children?.()}
</div>

<style>
  .page-background {
    background: rgba(75, 179, 153, 1);
    background: radial-gradient(
      at center,
      rgba(75, 179, 153, 1),
      rgba(44, 94, 167, 1)
    );
  }
</style>

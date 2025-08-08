<script>
  let { children } = $props();
</script>

<div class="background">
  {@render children?.()}
</div>

<style>
  .background {
    min-height: 100vh;
    background: rgba(75, 179, 153, 1);
    background: radial-gradient(
      at center,
      rgba(75, 179, 153, 1),
      rgba(44, 94, 167, 1)
    );
  }
</style>

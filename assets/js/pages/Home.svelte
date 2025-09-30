<script>
  import { inertia } from "@inertiajs/svelte";
  import { Provider } from "~shared/types/provider";

  const { provider } = $props();
</script>

<svelte:head>
  <title>Songy - Music Game Platform</title>
</svelte:head>

<div class="wrapper">
  {#if provider == Provider.SPOTIFY}
    <form class="providers" use:inertia={{ href: "/create", method: "post" }}>
      <button type="submit" class="btn btn-success w-3xs"> Create game </button>
    </form>
  {:else}
    <a href="/auth/spotify" class="btn btn-primary w-3xs">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
        <path
          d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm4.586 14.424c-.18.295-.563.387-.857.207-2.348-1.435-5.304-1.76-8.785-.964-.335.077-.67-.133-.746-.468-.077-.334.132-.67.467-.746 3.809-.87 7.077-.496 9.713 1.115.293.18.386.563.208.856zm1.223-2.723c-.226.367-.706.482-1.073.257-2.687-1.652-6.785-2.131-9.965-1.166-.413.125-.849-.106-.974-.518-.125-.413.106-.849.518-.974 3.632-1.102 8.147-.568 11.239 1.328.366.226.482.706.255 1.073zm.105-2.835C14.692 8.95 9.375 8.775 6.297 9.71c-.493.15-1.016-.128-1.166-.62-.15-.493.128-1.016.62-1.166 3.532-1.073 9.404-.865 13.115 1.338.445.264.590.837.326 1.282-.264.445-.837.590-1.282.326z"
        />
      </svg>
      Spotify
    </a>
  {/if}
</div>

<style>
  .wrapper {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1rem;
    padding: 2.5rem 1rem;
  }

  @media (min-width: 640px) {
    .wrapper {
      padding-left: 1.5rem;
      padding-right: 1.5rem;
    }
  }

  @media (min-width: 1024px) {
    .wrapper {
      padding-left: 2rem;
      padding-right: 2rem;
    }
  }

  form {
    display: contents;
  }
</style>

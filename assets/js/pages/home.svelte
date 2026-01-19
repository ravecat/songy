<script>
  import { inertia } from "@inertiajs/svelte";
  import { Provider } from "~shared/types/provider";
  import Logo from "~components/Logo.svelte";
  import { Users, ListOrdered, Trophy } from "lucide-svelte";
</script>

<svelte:head>
  <title>Songy - Music Game</title>
</svelte:head>

{#snippet spotify()}
  <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
    <path
      d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2zm4.586 14.424c-.18.295-.563.387-.857.207-2.348-1.435-5.304-1.76-8.785-.964-.335.077-.67-.133-.746-.468-.077-.334.132-.67.467-.746 3.809-.87 7.077-.496 9.713 1.115.293.18.386.563.208.856zm1.223-2.723c-.226.367-.706.482-1.073.257-2.687-1.652-6.785-2.131-9.965-1.166-.413.125-.849-.106-.974-.518-.125-.413.106-.849.518-.974 3.632-1.102 8.147-.568 11.239 1.328.366.226.482.706.255 1.073zm.105-2.835C14.692 8.95 9.375 8.775 6.297 9.71c-.493.15-1.016-.128-1.166-.62-.15-.493.128-1.016.62-1.166 3.532-1.073 9.404-.865 13.115 1.338.445.264.590.837.326 1.282-.264.445-.837.590-1.282.326z"
    />
  </svg>
{/snippet}

<div class="landing">
  <div class="rules-section">
    <div class="logo-container">
      <Logo />
    </div>
    <div class="rules-content">
      <h1 class="title">Music Quiz Game</h1>
      <ul class="rules-list">
        <li>
          <Users size={20} strokeWidth={2.5} />
          <span>Play with friends</span>
        </li>
        <li>
          <ListOrdered size={20} strokeWidth={2.5} />
          <span>Place songs on the timeline</span>
        </li>
        <li>
          <Trophy size={20} strokeWidth={2.5} />
          <span>Wins!</span>
        </li>
      </ul>
    </div>
  </div>

  <div class="actions">
    <div class="actions">
      <form
        use:inertia={{
          href: "/create",
          method: "post",
          data: { provider: Provider.APPLE },
        }}
      >
        <button type="submit" class="btn btn-apple w-3xs">
          Create game
        </button>
      </form>

      <form
        use:inertia={{
          href: "/create",
          method: "post",
          data: { provider: Provider.SPOTIFY },
        }}
      >
        <button type="submit" class="btn btn-primary w-3xs">
          {@render spotify()}
          Create game
        </button>
      </form>
    </div>
  </div>
</div>

<style>
  .landing {
    min-height: 100vh;
    display: flex;
    flex-direction: row;
  }

  .rules-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem 1.5rem;
    gap: 2rem;
    background-image: var(--landing-gradient);
    flex: 0 0 50%;
    overflow: hidden;
    opacity: 1;
    visibility: visible;
    transition:
      opacity var(--transition-fast),
      visibility var(--transition-fast),
      flex-basis var(--transition-fast),
      padding var(--transition-fast),
      gap var(--transition-fast);
  }

  .logo-container {
    height: clamp(60px, 15vw, 120px);
    width: clamp(60px, 15vw, 120px);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .rules-content {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    text-align: center;
    color: var(--color-info-content);
    max-width: 100%;
  }

  .title {
    font-size: clamp(1.25rem, 4.5vw, 2.5rem);
    font-weight: 700;
    line-height: var(--line-tight);
    text-align: center;
  }

  .rules-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    font-size: clamp(0.875rem, 4.5vw, 1.125rem);
    line-height: var(--line-relaxed);
  }

  .rules-list li {
    display: flex;
    align-items: baseline;
    gap: clamp(0.5rem, 1rem, 1rem);
  }

  .actions {
    flex: 0 0 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem 1.5rem;
    overflow: hidden;
    transition: flex-basis var(--transition-fast);
  }

  .actions {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    align-items: center;
  }

  .btn-primary {
    background: var(--spotify-green);
    color: var(--spotify-black);
    border-color: var(--spotify-green);
    box-shadow: none;
  }

  .btn-primary:hover {
    background: var(--spotify-green-hover);
    border-color: var(--spotify-green-hover);
    box-shadow: none;
  }

  .btn-apple {
    background: #ffffff;
    color: #0f172a;
    border-color: rgba(15, 23, 42, 0.12);
    box-shadow: 0 16px 30px rgba(15, 23, 42, 0.12);
  }

  .btn-apple:hover {
    background: #f8fafc;
    border-color: rgba(15, 23, 42, 0.2);
    box-shadow: 0 18px 36px rgba(15, 23, 42, 0.18);
  }

  @media (min-width: 640px) {
    .rules-section {
      padding: 3rem 2rem;
    }

    .rules-content {
      text-align: left;
    }
  }

  @media (min-width: 1024px) {
    .rules-section {
      padding: 4rem 3rem;
    }
  }

  @media (max-width: 639px) {
    .rules-section {
      opacity: 0;
      visibility: hidden;
      flex: 0 0 0%;
      padding: 0;
      gap: 0;
    }

    .actions {
      flex: 0 0 100%;
    }
  }
</style>

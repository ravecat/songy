<script lang="ts">
  import { getGameContext } from "~components/GameChannel.svelte";
  import { Users } from "lucide-svelte";

  const { game } = $derived.by(getGameContext);

  const playerCount = $derived(game?.participants?.length ?? 0);
</script>

<button class="participants-button" aria-label={`${playerCount} player${playerCount !== 1 ? 's' : ''} online`}>
  <Users size={20} strokeWidth={2.5} />
  <span class="participants-button__value">{playerCount}</span>
</button>

<style>
  .participants-button {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.35rem;
    width: 3rem;
    height: 3rem;
    padding: 0.4rem;
    box-sizing: border-box;
    background: transparent;
    border: none;
    cursor: pointer;
    border-radius: 0.5rem;
    color: white;
    padding: 0;
    transition: background-color 0.15s ease-out;
  }

  .participants-button :global(svg) {
    flex-shrink: 0;
    display: block;
  }

  .participants-button:hover {
    background-color: rgba(255, 255, 255, 0.1);
  }

  .participants-button:active {
    background-color: rgba(255, 255, 255, 0.2);
  }

  .participants-button__value {
    font-size: 1rem;
    font-weight: 600;
    line-height: 1;
    min-width: 1.25rem;
  }
</style>

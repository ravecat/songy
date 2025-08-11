<script>
  import { getChannelContext } from "@shared/context/channel";

  const { isOpen, close } = $props();
  const { state } = $derived(getChannelContext());

  let dialog = $state();

  const currentPlayer = $derived.by(() => {
    const currentPlayerUuid =
      state?.turn?.queue?.[state?.turn?.current_player_index];

    return state?.participants?.find(({ uuid }) => uuid === currentPlayerUuid);
  });

  $effect(() => {
    if (isOpen && dialog) {
      dialog.showModal();
    } else if (!isOpen && dialog) {
      dialog.close();
    }
  });
</script>

{#if isOpen}
  <dialog
    bind:this={dialog}
    onclose={() => close()}
    onclick={(e) => {
      if (e.target === dialog) close();
    }}
  >
    <div class="player-info">
      <img
        src={currentPlayer.avatar_url}
        alt={currentPlayer.name}
        class="player-avatar"
      />
      <h2>{currentPlayer.name} turn</h2>
    </div>
    <!-- svelte-ignore a11y_autofocus -->
    <button class="btn btn-primary w-full" autofocus onclick={() => close()}>
      Ready?
    </button>
  </dialog>
{/if}

<style>
  dialog {
    max-width: 400px;
    border-radius: 0.5rem;
    border: none;
    padding: 2rem;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    margin: 0;
    text-align: center;
    background: white;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }

  @media (max-width: 768px) {
    dialog {
      width: calc(100vw - 4rem);
      height: calc(100vh - 4rem);
      max-width: none;
      max-height: none;
    }
  }

  dialog::backdrop {
    background: rgba(0, 0, 0, 0.5);
  }

  dialog[open] {
    animation: zoom 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
  }

  @keyframes zoom {
    from {
      transform: translate(-50%, -50%) scale(0.95);
    }
    to {
      transform: translate(-50%, -50%) scale(1);
    }
  }

  dialog[open]::backdrop {
    animation: fade 0.2s ease-out;
  }

  @keyframes fade {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  h2 {
    margin: 0 0 1rem 0;
    color: #333;
    font-size: 1.5rem;
  }

  .player-info {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .player-avatar {
    width: 4rem;
    height: 4rem;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid #3b82f6;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }
</style>

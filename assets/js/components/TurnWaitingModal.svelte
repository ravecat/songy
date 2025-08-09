<script>
  const { isOpen, close } = $props();

  let dialog = $state();

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
    <h2>Turn Waiting</h2>
    <p>Waiting for your turn...</p>
    <!-- svelte-ignore a11y_autofocus -->
    <button autofocus onclick={() => close()}>OK</button>
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

  /* Mobile: fullscreen with margins */
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

  p {
    margin: 0 0 1.5rem 0;
    color: #666;
    font-size: 1rem;
  }

  button {
    background: #3b82f6;
    color: white;
    border: none;
    padding: 0.5rem 1.5rem;
    border-radius: 0.25rem;
    cursor: pointer;
    font-size: 1rem;
  }

  button:hover {
    background: #2563eb;
  }
</style>

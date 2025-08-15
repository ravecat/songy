<script>
  import { slide } from "svelte/transition";
  import { getGameContext } from "~components/GameContext.svelte";
  import { getScopeContext } from "~shared/context/scope";

  const { state } = $derived(getGameContext());
  const { user } = $derived(getScopeContext());
</script>

{#if state.participants && state.participants.length > 0}
  <div class="participants-header">
    {#each state.participants as participant}
      <div
        in:slide={{ duration: 400, axis: "y" }}
        out:slide={{ duration: 400, axis: "y" }}
        class="participant-wrapper"
      >
        <div class="participant-avatar">
          <img
            src={participant.avatar_url}
            alt={participant.name}
            class="avatar"
          />
        </div>

        {#if user && participant.uuid === user.uuid}
          <div class="star-indicator" aria-label="Your avatar">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="star-icon"
            >
              <defs>
                <linearGradient
                  id="starGradient"
                  x1="0%"
                  y1="0%"
                  x2="100%"
                  y2="100%"
                >
                  <stop offset="0%" style="stop-color:#fbbf24;stop-opacity:1" />
                  <stop
                    offset="50%"
                    style="stop-color:#f59e0b;stop-opacity:1"
                  />
                  <stop
                    offset="100%"
                    style="stop-color:#f97316;stop-opacity:1"
                  />
                </linearGradient>
                <linearGradient
                  id="starBorder"
                  x1="0%"
                  y1="0%"
                  x2="100%"
                  y2="100%"
                >
                  <stop
                    offset="0%"
                    style="stop-color:#d97706;stop-opacity:0.8"
                  />
                  <stop
                    offset="100%"
                    style="stop-color:#ea580c;stop-opacity:0.8"
                  />
                </linearGradient>
              </defs>
              <path
                d="M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"
                fill="url(#starGradient)"
                stroke="url(#starBorder)"
              />
            </svg>
          </div>
        {/if}

        <div class="participant-name">
          <div class="name-text">
            {participant.name}
          </div>
        </div>
      </div>
    {/each}
  </div>
{/if}

<style>
  .participants-header {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 50;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 1rem;
    padding: 1rem;
    background: linear-gradient(to bottom, rgba(0, 0, 0, 0.2), transparent);
    backdrop-filter: blur(4px);
  }

  .participant-wrapper {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    transition: all 0.3s ease;
  }

  .participant-avatar {
    width: 6rem;
    height: 6rem;
    border-radius: 0.75rem;
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(4px);
    overflow: hidden;
    border: 2px solid rgba(255, 255, 255, 0.3);
    box-shadow:
      0 10px 15px -3px rgba(0, 0, 0, 0.1),
      0 4px 6px -2px rgba(0, 0, 0, 0.05);
    transition: all 0.3s ease;
    padding: 0.25rem;
  }

  .participant-avatar:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-0.25rem);
    box-shadow:
      0 20px 25px -5px rgba(0, 0, 0, 0.1),
      0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }

  .avatar {
    width: 100%;
    height: 100%;
    object-fit: cover;
    border-radius: 0.5rem;
  }

  .participant-name {
    margin-top: 0.5rem;
    text-align: center;
  }

  .name-text {
    font-size: 0.875rem;
    font-weight: 500;
    color: white;
    max-width: 6rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .star-indicator {
    position: absolute;
    top: -0.8rem;
    right: -0.8rem;
    width: 2.4rem;
    height: 2.4rem;
    z-index: 10;
    filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3));
    pointer-events: none;
    transform: rotate(15deg);
  }

  .star-icon {
    width: 100%;
    height: 100%;
  }
</style>

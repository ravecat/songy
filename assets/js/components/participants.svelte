<script lang="ts">
  import type { Game } from "~contracts";
  import { getGameContext } from "~/contexts/game";

  type Participant = Game["participants"][string];

  const session = getGameContext();
  const game = $derived($session.snapshot?.game ?? null);
  const participants = $derived(game?.participants ?? {});
  const queue = $derived(game?.queue ?? []);
  const participantList = $derived(Object.values(participants));

  const visibleParticipants = $derived(
    queue
      .map((participantId) => participants[participantId])
      .filter((participant): participant is Participant => Boolean(participant))
      .slice(0, 3),
  );

  const playerCount = $derived(participantList.length);
</script>

<div
  class="participants-indicator flex items-center justify-end text-white"
  role="status"
  aria-live="polite"
  aria-atomic="true"
  aria-label={`${playerCount} player${playerCount !== 1 ? "s" : ""} online`}
>
  <div class="flex -space-x-2 rtl:space-x-reverse">
    {#each visibleParticipants as participant (participant.id)}
      <div class="avatar">
        <div
          class="ring-primary ring-offset-base-100 w-6 rounded-full ring-2 ring-offset-1 sm:w-7"
        >
          <img src={participant.avatar_url} alt="" />
        </div>
      </div>
    {/each}

    <div class="avatar avatar-placeholder">
      <div
        class="[background-image:var(--room-gradient)] ring-primary ring-offset-base-100 w-6 rounded-full text-white ring-2 ring-offset-1 sm:w-7"
      >
        <span
          aria-hidden="true"
          class="text-[0.625rem] font-semibold leading-none sm:text-[0.75rem]"
        >
          {playerCount}
        </span>
      </div>
    </div>
  </div>
</div>

<style>
  .participants-indicator {
    min-width: 0;
    max-width: 100%;
  }
</style>

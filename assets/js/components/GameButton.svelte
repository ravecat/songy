<script>
  import { getChannelContext } from "@shared/context/channel.js";

  const { channel } = $derived(getChannelContext());
</script>

<div class="flex justify-center">
  <button
    class="w-full px-8 py-4 bg-white text-purple-600 rounded-lg font-bold text-xl hover:bg-white/90 transition-all duration-300 hover:scale-105 shadow-2xl border-4 border-white/50"
    onclick={() => channel.push("start_game", {})}
  >
    Start
  </button>
</div>

<script>
  import { scale } from "svelte/transition";

  const mock = {
    artist: "Taylor Swift",
    album: "1989",
    title: "Shake It Off",
    year: "2014",
  };

  let { track = mock } = $props();
</script>

<div
  class="w-32 h-32 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-lg shadow-lg mx-auto flex items-center justify-center"
  in:scale={{ duration: 400 }}
  out:scale={{ duration: 400, start: 0 }}
>
  <div class="text-center w-full px-2">
    <div class="text-gray-800 font-semibold mb-2 text-sm">
      {track.artist}
    </div>
    <div class="mb-2">
      <span
        class="text-4xl font-bold text-black leading-none tracking-wide scale-y-[0.8]"
      >
        {track.year}
      </span>
    </div>
    <div class="text-sm italic text-gray-800">{track.title}</div>
  </div>
</div>

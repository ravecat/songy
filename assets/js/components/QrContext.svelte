<script lang="ts" module>
  import { createContext } from "svelte";

  export const [getQrContext, setQrContext] = createContext<{ svg: string }>();
</script>

<script lang="ts">
  import type { Snippet } from "svelte";

  let { svg, children }: { svg: string; children: Snippet } = $props();

  function makeResponsive(svgString: string): string {
    const sizeMatch = svgString.match(/width="(\d+)"/);
    if (!sizeMatch) return svgString;

    const size = sizeMatch[1];
    return svgString
      .replace(/width="\d+"/, "")
      .replace(/height="\d+"/, "")
      .replace("<svg ", `<svg viewBox="0 0 ${size} ${size}" `);
  }

  const responsiveSvg = $derived(makeResponsive(svg));

  setQrContext({ get svg() { return responsiveSvg; } });
</script>

{@render children?.()}

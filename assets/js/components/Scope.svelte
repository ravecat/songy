<script>
  import { setContext } from "svelte";
  import { getChannelContext } from "@shared/context/channel";

  let { children } = $props();

  const { channel } = $derived.by(getChannelContext);

  let context = $state({ user: null });

  $effect(() => {
    channel
      .push("get_current_user", {})
      .receive("ok", (response) => {
        context.user = response;
      })
      .receive("error", (error) => {
        console.error("Failed to get user:", error);
      });
  });

  setContext("scope", context);
</script>

{@render children()}

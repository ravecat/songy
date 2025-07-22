/**
 * Hook for Phoenix channel management
 * @param {Object} options - Channel options
 * @param {Socket} options.socket - Phoenix Socket
 * @param {string} options.topic - Channel topic
 * @param {Object} [options.payload] - Optional payload for join
 * @param {Object} [options.join] - Join response handlers {ok, error, timeout}
 * @param {Function} [options.onError] - Callback on channel error
 * @param {Function} [options.onClose] - Callback on channel close
 * @param {Object} [options.on] - Event handlers object {eventName: handler}
 * @returns {Channel} - Phoenix channel instance
 */
export function useChannel(options) {
  const {
    socket,
    topic,
    payload = {},
    join = {},
    onError,
    onClose,
    on = {},
  } = options;

  const joinCallbacks = {
    ok: (resp) => console.info(`Joined ${topic} successfully`, resp),
    error: (resp) => console.info(`Unable to join ${topic}`, resp),
    timeout: () => console.info(`Networking issue with ${topic}`),
    ...join,
  };

  const channel = socket.channel(topic, payload);

  $effect(() => {
    channel
      .join()
      .receive("ok", joinCallbacks.ok)
      .receive("error", joinCallbacks.error)
      .receive("timeout", joinCallbacks.timeout);

    Object.entries(on).forEach(([eventName, handler]) => {
      channel.on(eventName, handler);
    });

    channel.onError(
      onError ||
        (() => {
          console.error(`Channel error on ${topic}, attempting to rejoin...`);
        })
    );

    channel.onClose(
      onClose ||
        (() => {
          console.info(`Channel ${topic} closed`);
        })
    );

    return () => {
      channel.leave();
    };
  });

  return channel;
}

defmodule SongyWeb.UserSocket do
  use Phoenix.Socket

  require Logger

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels

  channel "room:*", SongyWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"user_token" => user_token} = params, socket, _connect_info) do
    with {:ok, user_uuid} <- verify_user_token(socket, user_token),
         provider <- verify_provider_token(socket, params) do
      socket =
        socket
        |> assign(:current_user_uuid, user_uuid)
        |> assign(:provider, provider)

      {:ok, socket}
    else
      {:error, reason} ->
        Logger.error("Failed to connect user socket: #{inspect(reason)}")

        :error
    end
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  # Socket IDs are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.SongyWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user_uuid}"

  defp verify_user_token(socket, user_token) do
    case Phoenix.Token.verify(socket, "current_user", user_token, max_age: 86400) do
      {:ok, user_uuid} ->
        Logger.info("User socket connected for user ID: #{user_uuid}")

        {:ok, user_uuid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_provider_token(socket, %{"provider_token" => provider_token}) do
    case Phoenix.Token.verify(socket, "current_provider", provider_token, max_age: 86400) do
      {:ok, provider} ->
        Logger.info("User socket connected with provider: #{inspect(provider)}")

        provider

      _ ->
        nil
    end
  end

  defp verify_provider_token(_socket, _params), do: nil
end

defmodule Songy.Boundary.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """
  alias Songy.Core.Provider

  require Logger

  @spec transfer_playback(provider :: Provider.t(), payload :: map()) ::
          {:ok, :transferred} | {:ok, :transfer_failed} | {:ok, :no_credentials} | {:ok, :no_device_id}
  def transfer_playback(provider, %{"device_id" => device_id}) do
    case provider do
      %{id: :spotify, meta: %{access_token: token}} when not is_nil(token) ->
        credentials = struct(Spotify.Credentials, %{access_token: token})

        case Spotify.Player.transfer_playback(credentials, [device_id]) do
          :ok ->
            Logger.info("Successfully transferred playback to device #{device_id}")
            {:ok, :transferred}

          {:error, reason} ->
            Logger.warning("Failed to transfer playback to device #{device_id}: #{inspect(reason)}")
            {:ok, :transfer_failed}
        end

      _ ->
        Logger.warning("No valid Spotify credentials for playback transfer")
        {:ok, :no_credentials}
    end
  end

  def transfer_playback(_socket, _payload) do
    {:ok, :no_device_id}
  end
end

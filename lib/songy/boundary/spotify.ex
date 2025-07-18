defmodule Songy.Boundary.Spotify do
  @moduledoc """
  Boundary module for Spotify-related functionality in the Songy application.

  This module provides functions to interact with Spotify's API, including
  managing playback, searching for tracks, and handling user authentication.
  """
  alias Songy.Core.Provider

  require Logger

  @spec transfer_playback(provider :: Provider.t(), payload :: map()) ::
          {:ok, :transferred} | {:error, :no_credentials | :invalid_provider | :no_device_id | :transfer_failed}
  def transfer_playback(provider, %{"device_id" => device_id}) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.transfer_playback(credentials, [device_id]) do
      Logger.info("Successfully transferred playback to device #{device_id}")
      {:ok, :transferred}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

      {:error, reason} ->
        Logger.warning("Failed to transfer playback to device #{device_id}: #{inspect(reason)}")
        {:error, :transfer_failed}
    end
  end

  def transfer_playback(_, _), do: {:error, :no_device_id}

  @spec start_playback(provider :: Provider.t(), params :: keyword()) ::
          {:ok, :playback_started} | {:error, :no_credentials | :invalid_provider | :playback_start_failed}
  def start_playback(provider, params \\ []) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.play(credentials, params) do
      Logger.info("Successfully started playback with options: #{inspect(params)}")
      {:ok, :playback_started}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

      {:error, reason} ->
        Logger.warning("Spotify API failed to start playback: #{inspect(reason)}")
        {:error, :playback_start_failed}
    end
  end

  @spec pause_playback(provider :: Provider.t(), params :: keyword()) ::
          {:ok, :playback_paused} | {:error, :no_credentials | :invalid_provider | :playback_pause_failed}
  def pause_playback(provider, params \\ []) do
    with {:ok, provider} <- validate_provider(provider),
         {:ok, credentials} <- extract_credentials(provider),
         :ok <- Spotify.Player.pause(credentials, params) do
      Logger.info("Successfully paused playback with options: #{inspect(params)}")
      {:ok, :playback_paused}
    else
      {:error, reason} when reason in [:no_credentials, :invalid_provider] ->
        {:error, reason}

      {:error, reason} ->
        Logger.warning("Spotify API failed to pause playback: #{inspect(reason)}")
        {:error, :playback_pause_failed}
    end
  end

  defp validate_provider(%{id: :spotify} = provider), do: {:ok, provider}
  defp validate_provider(_), do: {:error, :invalid_provider}

  defp extract_credentials(%{meta: %{access_token: token}}) when not is_nil(token) do
    credentials = struct(Spotify.Credentials, %{access_token: token})
    {:ok, credentials}
  end

  defp extract_credentials(_), do: {:error, :no_credentials}
end

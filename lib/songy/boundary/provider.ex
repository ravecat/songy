defmodule Songy.Boundary.Provider do
  @moduledoc """
  Behaviour and facade for music provider operations.

  Business flows call this module with provider data, while explicit adapter
  selection stays internal to the provider boundary.
  """

  alias Songy.Core.Provider.Apple
  alias Songy.Core.Provider.ITunes
  alias Songy.Core.Provider.Spotify
  alias Songy.Core.Track

  @type id :: :spotify | :apple | :itunes

  @callback ensure(struct()) :: {:ok, id(), struct()} | {:error, atom()}
  @callback start_playback(struct(), Track.t()) :: {:ok, :playback_started} | {:error, atom()}
  @callback pause_playback(struct()) :: {:ok, :playback_paused} | {:error, atom()}
  @callback search_random_track(struct()) :: {:ok, Track.t()} | {:error, atom()}
  @callback search(struct(), keyword()) :: {:ok, [Track.t()]} | {:error, atom()}

  @spec ensure(term()) :: {:ok, id(), struct()} | {:error, atom()}
  def ensure(provider), do: dispatch(provider, :ensure, [provider])

  @spec start_playback(term(), Track.t()) :: {:ok, :playback_started} | {:error, atom()}
  def start_playback(provider, track), do: dispatch(provider, :start_playback, [provider, track])

  @spec pause_playback(term()) :: {:ok, :playback_paused} | {:error, atom()}
  def pause_playback(provider), do: dispatch(provider, :pause_playback, [provider])

  @spec search_random_track(term()) :: {:ok, Track.t()} | {:error, atom()}
  def search_random_track(provider), do: dispatch(provider, :search_random_track, [provider])

  @spec search(term(), keyword()) :: {:ok, [Track.t()]} | {:error, atom()}
  def search(provider, params), do: dispatch(provider, :search, [provider, params])

  defp dispatch(provider, function, args) do
    with {:ok, adapter} <- adapter_for(provider) do
      apply(adapter, function, args)
    end
  end

  defp adapter_for(%Spotify{}), do: {:ok, Songy.Boundary.Provider.Spotify}
  defp adapter_for(%Apple{}), do: {:ok, Songy.Boundary.Provider.Apple}
  defp adapter_for(%ITunes{}), do: {:ok, Songy.Boundary.Provider.ITunes}
  defp adapter_for(_), do: {:error, :not_supported}
end

defmodule Songy.Boundary.Provider do
  @moduledoc """
  Behaviour and facade for music provider operations.

  Business flows call this module with provider sessions, while adapter
  selection stays outside the facade.
  """

  alias Songy.Core.Track
  alias Songy.Provider.Session

  @callback ensure(struct()) :: {:ok, atom(), struct()} | {:error, atom()}
  @callback start_playback(struct(), Track.t()) :: {:ok, :playback_started} | {:error, atom()}
  @callback pause_playback(struct()) :: {:ok, :playback_paused} | {:error, atom()}
  @callback search_random_track(struct()) :: {:ok, Track.t()} | {:error, atom()}
  @callback search_cover_tracks(struct()) :: {:ok, [Track.t()]} | {:error, atom()}
  @callback search(struct(), keyword()) :: {:ok, [Track.t()]} | {:error, atom()}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Songy.Boundary.Provider
    end
  end

  @spec ensure(Session.t()) :: {:ok, Session.t()} | {:error, atom()}
  def ensure(%Session{adapter: adapter, data: data} = session) when is_atom(adapter) do
    case adapter.ensure(data) do
      {:ok, id, new_data} -> {:ok, %Session{session | id: id, data: new_data}}
      {:error, reason} -> {:error, reason}
    end
  end

  def ensure(_), do: {:error, :not_supported}

  @spec start_playback(Session.t(), Track.t()) :: {:ok, :playback_started} | {:error, atom()}
  def start_playback(%Session{adapter: adapter, data: data}, track) when is_atom(adapter) do
    adapter.start_playback(data, track)
  end

  def start_playback(_, _track), do: {:error, :not_supported}

  @spec pause_playback(Session.t()) :: {:ok, :playback_paused} | {:error, atom()}
  def pause_playback(%Session{adapter: adapter, data: data}) when is_atom(adapter) do
    adapter.pause_playback(data)
  end

  def pause_playback(_), do: {:error, :not_supported}

  @spec search_random_track(Session.t()) :: {:ok, Track.t()} | {:error, atom()}
  def search_random_track(%Session{adapter: adapter, data: data}) when is_atom(adapter) do
    adapter.search_random_track(data)
  end

  def search_random_track(_), do: {:error, :not_supported}

  @spec search_cover_tracks(Session.t()) :: {:ok, [Track.t()]} | {:error, atom()}
  def search_cover_tracks(%Session{adapter: adapter, data: data}) when is_atom(adapter) do
    adapter.search_cover_tracks(data)
  end

  def search_cover_tracks(_), do: {:error, :not_supported}

  @spec search(Session.t(), keyword()) :: {:ok, [Track.t()]} | {:error, atom()}
  def search(%Session{adapter: adapter, data: data}, params) when is_atom(adapter) do
    adapter.search(data, params)
  end

  def search(_, _params), do: {:error, :not_supported}
end

defmodule Songy.Core.Player do
  @moduledoc """
  Represents player state for a game session.

  Player manages internal playback state within a game.
  State is controlled entirely by game logic, not external input.
  """

  use TypedStruct

  @derive {Jason.Encoder, only: [:is_playback]}

  typedstruct do
    field :is_playback, boolean(), default: false
  end

  @doc """
  Creates a new player with default state.

  ## Examples
      iex> Player.new()
      %Player{is_playback: false}
  """
  @spec new() :: t()
  def new, do: %__MODULE__{is_playback: false}

  @doc """
  Toggles playback state.

  ## Examples
      iex> player = Player.new()
      iex> Player.toggle_playback(player)
      %Player{is_playback: true}

      iex> player = %Player{is_playback: true}
      iex> Player.toggle_playback(player)
      %Player{is_playback: false}
  """
  @spec toggle_playback(t()) :: t()
  def toggle_playback(%__MODULE__{is_playback: current}) do
    %__MODULE__{is_playback: !current}
  end

  @doc """
  Sets playback state to the given value.

  ## Examples
      iex> player = Player.new()
      iex> Player.set_playback(player, true)
      %Player{is_playback: true}
  """
  @spec set_playback(t(), boolean()) :: t()
  def set_playback(%__MODULE__{}, state) when is_boolean(state) do
    %__MODULE__{is_playback: state}
  end

  @doc """
  Checks if player is currently playing.

  ## Examples
      iex> player = Player.new()
      iex> Player.playing?(player)
      false

      iex> player = %Player{is_playback: true}
      iex> Player.playing?(player)
      true
  """
  @spec playing?(t()) :: boolean()
  def playing?(%__MODULE__{is_playback: is_playback}), do: is_playback
end

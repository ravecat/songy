defmodule Songy do
  @moduledoc """
  The Core context provides the business domain layer for the Songy music quiz game.

  This module contains the core entities and business logic for the game:
  - Game: Multiplayer game rooms with participants
  - User: Game players (separate from authenticated users)
  - Track: Musical compositions with metadata
  - Provider: External music service integrations

  All entities are designed to be stored in memory during game sessions
  and are not persisted to the database.
  """

  alias Songy.Core.{Game, User, Track, Provider}

  # Game management functions

  @doc """
  Creates a new game with owner and optional maximum participants.

  ## Examples
      iex> Songy.create_game("user123")
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 6, owner_uuid: "user123"}

      iex> Songy.create_game("user123", 4)
      %Game{uuid: "a1b2c3d4", participants: [], max_participants: 4, owner_uuid: "user123"}
  """
  @spec create_game(String.t(), pos_integer()) :: Game.t()
  def create_game(owner_uuid, max_participants \\ 6) when is_binary(owner_uuid) do
    Game.new(owner_uuid, max_participants)
  end

  @doc """
  Adds a user to a game.
  """
  @spec join_game(Game.t(), User.t()) :: {:ok, Game.t()} | {:error, atom()}
  def join_game(%Game{} = game, %User{} = user) do
    Game.add_participant(game, user)
  end

  @doc """
  Removes a user from a game.
  """
  @spec leave_game(Game.t(), String.t()) :: {:ok, Game.t()} | {:error, atom()}
  def leave_game(%Game{} = game, user_uuid) do
    Game.remove_participant(game, user_uuid)
  end

  @doc """
  Starts a game by changing its status to in_progress.
  """
  @spec start_game(Game.t()) :: Game.t()
  def start_game(%Game{} = game) do
    Game.update_status(game, :in_progress)
  end

  @doc """
  Finishes a game by changing its status to finished.
  """
  @spec finish_game(Game.t()) :: Game.t()
  def finish_game(%Game{} = game) do
    Game.update_status(game, :finished)
  end

  # User management functions

  @doc """
  Creates a new game user with a unique UUID.

  ## Examples
      iex> Songy.create_user()
      %User{uuid: "a1b2c3d4e5f6..."}
  """
  @spec create_user() :: User.t()
  def create_user() do
    User.new()
  end

  # Track management functions

  @doc """
  Creates a new track with the given attributes.

  ## Examples
      iex> Songy.create_track(id: "spotify:track:4uLU6hMCjMI75M1A2tKUQC", title: "Bohemian Rhapsody", artist: "Queen", year: 1975)
      %Track{id: "spotify:track:4uLU6hMCjMI75M1A2tKUQC", title: "Bohemian Rhapsody", artist: "Queen", year: 1975}
  """
  @spec create_track(keyword()) :: Track.t()
  def create_track(attrs) do
    Track.new(attrs)
  end

  @doc """
  Creates a music provider instance.

  ## Examples
      iex> Songy.create_provider(:spotify, %{api_key: "key123"})
      %Provider{id: :spotify, meta: %{api_key: "key123"}}
  """
  @spec create_provider(atom(), map()) :: Provider.t()
  def create_provider(id, meta \\ %{}) do
    Provider.new(id, meta)
  end

  # Helper functions

  @doc """
  Checks if a user can join a specific game.
  """
  @spec can_join_game?(Game.t(), User.t()) :: boolean()
  def can_join_game?(%Game{} = game, %User{} = user) do
    not Game.full?(game) and
      not Enum.any?(game.participants, &(&1.uuid == user.uuid)) and
      game.status == :waiting
  end
end

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
end

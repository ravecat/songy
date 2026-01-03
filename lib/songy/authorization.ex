defmodule Songy.Authorization do
  @moduledoc """
  Authorization system using Casbin for role-based access control (RBAC).

  This module starts the Casbin enforcer and provides functions to check permissions
  based on game state. The permission rules are defined in priv/authorization/policies.csv
  with the model in priv/authorization/model.conf.

  """

  use GenServer

  require Logger

  alias Casbin.EnforcerServer
  alias Casbin.EnforcerSupervisor
  alias Songy.Core.Game

  @enforcer_name :songy_authorization_enforcer
  @model_path "priv/authorization/model.conf"
  @policy_path "priv/authorization/policies.csv"

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if a user can perform an action in a game context.

  Returns :ok if authorized, {:error, :unauthorized} otherwise.

  Each user resolves to a single subject (`owner`, `player`, or `challenger`)
  based on the current game state.

  ## Examples

      iex> Authorization.can?(game, user_id, :start_playback)
      :ok

      iex> Authorization.can?(game, user_id, :start_game)
      {:error, :unauthorized}
  """
  @spec can?(Game.t(), String.t() | nil, atom()) :: :ok | {:error, :unauthorized}
  def can?(game, user_id, action) do
    subject = subject(game, user_id)
    state = state(game)
    phase = phase(game)

    authorized = allow?(subject, state, phase, action)

    if authorized do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @impl true
  def init(_opts) do
    with {:ok, _pid} <- EnforcerSupervisor.start_enforcer(@enforcer_name, @model_path),
         :ok <- EnforcerServer.load_policies(@enforcer_name, @policy_path) do
      Logger.info("Casbin enforcer initialized")
      {:ok, %{}}
    else
      {:error, {:already_started, _pid}} ->
        :ok = EnforcerServer.load_policies(@enforcer_name, @policy_path)
        Logger.info("Casbin enforcer initialized")
        {:ok, %{}}

      {:error, reason} ->
        Logger.error("Failed to start Casbin enforcer: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  # Private functions

  @doc false
  @spec subject(Game.t(), String.t() | nil) :: String.t() | nil
  defp subject(_game, nil) do
    nil
  end

  defp subject(game, user_id) do
    is_owner = game.owner_id == user_id
    active_player = Enum.at(game.queue, game.cursor)
    is_active = active_player == user_id

    cond do
      is_owner -> "owner"
      is_active -> "player"
      true -> "challenger"
    end
  end

  defp allow?(nil, _state, _phase, _action), do: false

  defp allow?(subject, state, phase, action) when is_atom(action) do
    EnforcerServer.allow?(@enforcer_name, [subject, state, phase, Atom.to_string(action)])
  end

  @doc false
  @spec state(Game.t()) :: String.t()
  defp state(%Game{status: status}), do: to_string(status)

  @doc false
  @spec phase(Game.t()) :: String.t()
  defp phase(%Game{turn: %{phase: phase}}), do: to_string(phase)
  defp phase(_), do: to_string(nil)
end

defmodule Songy.Boundary.GameSession do
  alias Songy.Boundary.Game
  alias Songy.Boundary.Player
  alias Songy.Core
  alias Songy.Providers

  @id_size 2

  @default_opts [max_participants: 8, max_score: 10]

  @spec create_game_session(String.t(), keyword()) :: {:ok, Core.Game.t()} | {:error, term()}
  def create_game_session(owner_id, opts \\ []) when is_binary(owner_id) and is_list(opts) do
    game_id = generate_session_id()
    opts = Keyword.merge(@default_opts, Keyword.merge(opts, id: game_id, owner_id: owner_id))

    with {:ok, _pid} <-
           DynamicSupervisor.start_child(
             Songy.Supervisor.GameSession,
             {Game, opts}
           ),
         {:ok, game} <- Game.get_state(game_id) do
      {:ok, game}
    else
      {:error, {:already_started, _pid}} -> {:error, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec end_game_session(String.t(), term(), timeout()) :: :ok
  def end_game_session(game_id, reason \\ :normal, timeout \\ :infinity) do
    case lookup_game(game_id) do
      {:ok, pid} -> :gen_statem.stop(pid, reason, timeout)
      {:error, _} -> :ok
    end
  end

  @spec lookup_game_session(String.t()) ::
          {:ok, pid()} | {:error, :game_session_not_found}
  def lookup_game_session(game_id) when is_binary(game_id) or is_atom(game_id) do
    lookup_game(game_id)
  end

  @spec game_session_exists?(String.t()) :: boolean()
  def game_session_exists?(game_id) when is_binary(game_id) do
    case lookup_game(game_id) do
      {:ok, _pid} -> true
      {:error, _} -> false
    end
  end

  @spec start_game_session(String.t()) :: {:ok, Core.Game.t()} | {:error, term()}
  def start_game_session(game_id) when is_binary(game_id) do
    with {:ok, game} <- Game.get_state(game_id),
         {:ok, provider} <- Providers.lookup(:providers, game.owner_id),
         {:ok, track} <- Player.search_random_track(provider),
         {:ok, _game} <- Game.set_track(game_id, track),
         {:ok, game} <- Game.start_game(game_id) do
      {:ok, game}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec start_playback(String.t()) :: {:ok, Core.Game.t()} | {:error, term()}
  def start_playback(game_id) when is_binary(game_id) do
    with {:ok, game} <- Game.get_state(game_id),
         {:ok, provider} <- Providers.lookup(:providers, game.owner_id),
         {:ok, track} <- Game.get_track(game_id),
         {:ok, :playback_started} <- Player.start_playback(provider, track),
         {:ok, game} <- Game.start_playback(game_id) do
      {:ok, game}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec pause_playback(String.t()) :: {:ok, Core.Game.t()} | {:error, term()}
  def pause_playback(game_id) when is_binary(game_id) do
    with {:ok, game} <- Game.get_state(game_id),
         {:ok, provider} <- Providers.lookup(:providers, game.owner_id),
         {:ok, :playback_paused} <- Player.pause_playback(provider),
         {:ok, game} <- Game.pause_playback(game_id) do
      {:ok, game}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defdelegate owner?(game_id, user_id), to: Game
  defdelegate next_phase(game_id), to: Game

  defdelegate update_timeline(game_id, track, user_id), to: Game
  defdelegate update_timeline(game_id, track, user_id, position), to: Game
  defdelegate update_timeline(game_id, track, user_id, position, timeout), to: Game

  defdelegate make_assumption(game_id, user_id), to: Game
  defdelegate make_assumption(game_id, user_id, position), to: Game
  defdelegate make_assumption(game_id, user_id, position, timeout), to: Game

  defdelegate reorder_timeline(game_id, user_id), to: Game
  defdelegate reorder_timeline(game_id, user_id, position), to: Game
  defdelegate reorder_timeline(game_id, user_id, position, timeout), to: Game

  defdelegate increment_score(game_id, user_id), to: Game
  defdelegate increment_score(game_id, user_id, points), to: Game
  defdelegate increment_score(game_id, user_id, points, timeout), to: Game

  defdelegate get_state(game_id), to: Game

  defp generate_session_id do
    @id_size |> :crypto.strong_rand_bytes() |> Base.encode32(padding: false)
  end

  defp lookup_game(game_id) do
    Game.lookup_game(game_id)
  end
end

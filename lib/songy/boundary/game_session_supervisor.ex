defmodule Songy.Boundary.GameSessionSupervisor do
  @moduledoc """
  Per-game supervisor that owns the Game and Turn processes.
  """

  use Supervisor

  alias Songy.Boundary.Game
  alias Songy.Boundary.Turn

  def child_spec(opts) do
    game_id = Keyword.fetch!(opts, :id)

    %{
      id: {__MODULE__, game_id},
      start: {__MODULE__, :start_link, [opts]},
      restart: :temporary
    }
  end

  def start_link(opts) do
    game_id = Keyword.fetch!(opts, :id)
    Supervisor.start_link(__MODULE__, opts, name: via(game_id))
  end

  @impl true
  def init(opts) do
    children = [
      {Game, opts},
      {Turn, opts}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def via(game_id) do
    {:via, Registry, {Songy.Registry, {:session, game_id}}}
  end
end

defmodule Songy.Core.Provider.Apple do
  @moduledoc """
  Represents Apple Music provider struct.

  Developer Token is accessed from application config and shared across all users.
  Empty struct serves as a type marker for pattern matching with different providers.
  """

  defstruct []

  @type t :: %__MODULE__{}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Returns Developer Token from application config.

  Token is valid for up to 6 months and manually updated via environment variable.
  Configured via APPLE_MUSIC_ACCESS_TOKEN in runtime.exs.
  """
  @spec access_token() :: String.t()
  def access_token do
    Application.fetch_env!(:songy, :apple)[:access_token]
  end
end

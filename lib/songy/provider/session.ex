defmodule Songy.Provider.Session do
  @moduledoc """
  Normalized provider session stored in ETS.

  A session keeps provider identity, adapter module, and provider-specific data
  together so the provider facade does not need to infer the adapter from
  concrete data structs.
  """

  alias Songy.Core.Provider.Apple
  alias Songy.Core.Provider.ITunes
  alias Songy.Core.Provider.Spotify

  @enforce_keys [:adapter, :data, :id]
  defstruct [:adapter, :data, :id]

  @type t :: %__MODULE__{
          adapter: module(),
          data: struct(),
          id: atom()
        }

  @spec normalize(t() | struct()) :: {:ok, t()} | {:error, :not_supported}
  def normalize(%__MODULE__{} = session), do: {:ok, session}

  def normalize(%Spotify{} = data) do
    {:ok, %__MODULE__{id: :spotify, adapter: Songy.Boundary.Provider.Spotify, data: data}}
  end

  def normalize(%Apple{} = data) do
    {:ok, %__MODULE__{id: :apple, adapter: Songy.Boundary.Provider.Apple, data: data}}
  end

  def normalize(%ITunes{} = data) do
    {:ok, %__MODULE__{id: :itunes, adapter: Songy.Boundary.Provider.ITunes, data: data}}
  end

  def normalize(_), do: {:error, :not_supported}

  @spec normalize!(t() | struct()) :: t()
  def normalize!(value) do
    case normalize(value) do
      {:ok, session} -> session
      {:error, :not_supported} -> raise ArgumentError, "unsupported provider session: #{inspect(value)}"
    end
  end

  @spec put_data(t(), struct()) :: t()
  def put_data(%__MODULE__{} = session, data), do: %{session | data: data}
end

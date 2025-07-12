defmodule Songy.Core.Provider do
  @moduledoc """
  Provides a common interface for media providers.
  """

  use TypedStruct

  defmodule Behaviour do
    @moduledoc """
    Behaviour for provider-specific metadata enhancement.
    """

    alias Songy.Core.Provider

    @callback new(meta :: map()) :: Provider.t()
    @callback update(provider :: Provider.t(), patch :: map()) :: Provider.t()
  end

  @derive {Jason.Encoder, only: [:id, :meta]}

  typedstruct do
    field :id, atom()
    field :meta, map()
  end

  @doc """
  Creates a new provider with optional metadata enhancement.

  ## Examples

      iex> Provider.new(:spotify, %{custom_field: "value"})
      %Provider{id: :spotify, meta: %{custom_field: "value", expires_at: ~U[...]}}

  """
  @spec new(atom(), map()) :: %__MODULE__{}
  def new(id, meta \\ %{})
  def new(:spotify, meta), do: __MODULE__.Spotify.new(meta)
  def new(id, meta), do: %__MODULE__{id: id, meta: meta}

  @doc """
  Updates provider metadata using provider-specific implementations.

  Falls back to basic map merge if no specific provider implementation exists.

  ## Examples

      iex> provider = Provider.new(:spotify, %{token: "old"})
      iex> Provider.update(provider, %{token: "new"})
      %Provider{id: :spotify, meta: %{token: "new", expires_at: ~U[...]}}

      iex> provider = Provider.new(:unknown, %{data: "old"})
      iex> Provider.update(provider, %{data: "new"})
      %Provider{id: :unknown, meta: %{data: "new"}}

  """
  def update(%__MODULE__{id: :spotify} = provider, patch),
    do: __MODULE__.Spotify.update(provider, patch)

  def update(%__MODULE__{meta: meta} = provider, patch),
    do: %{provider | meta: Map.merge(meta, patch)}

  defmodule Spotify do
    @moduledoc """
    Spotify provider implementation.
    """
    alias Songy.Core.Provider

    @behaviour Songy.Core.Provider.Behaviour

    @spotify_token_expires_in 3600

    @impl true
    def new(%{access_token: _token} = credentials) do
      credential_data = normalize_credentials(credentials)

      meta =
        credential_data
        |> extend_with_expires_at()

      %Provider{id: :spotify, meta: meta}
    end

    @impl true
    def new(meta) do
      %Provider{id: :spotify, meta: meta}
    end

    @doc """
    Updates Spotify provider metadata.
    """
    @impl true
    def update(
          %Provider{id: _id, meta: meta} = provider,
          %{access_token: _token} = credentials
        ) do
      credential_data = normalize_credentials(credentials)

      meta =
        meta
        |> Map.merge(credential_data)
        |> extend_with_expires_at()

      %{provider | meta: meta}
    end

    @impl true
    def update(%Provider{id: _id, meta: meta} = provider, patch) do
      meta = Map.merge(meta, patch)

      %{provider | meta: meta}
    end

    defp normalize_credentials(credentials) when is_struct(credentials) do
      Map.from_struct(credentials)
    end

    defp normalize_credentials(credentials) when is_map(credentials) do
      credentials
    end

    defp extend_with_expires_at(meta) do
      expires_at = DateTime.utc_now() |> DateTime.add(@spotify_token_expires_in, :second)

      Map.put(meta, :expires_at, expires_at)
    end
  end
end

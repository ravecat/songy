defprotocol Songy.Boundary.Provider do
  @fallback_to_any true

  @moduledoc """
  Protocol for music provider management operations.

  Defines a unified interface for ensuring provider data validity and freshness
  across different music providers (Spotify, Apple Music, YouTube Music, etc.).

  All functions return standardized response tuples with generic error atoms
  for consistent error handling across the application.
  """

  @doc """
  Ensures that provider credentials and data are fresh and valid.

  This function should check if the provided credentials need refreshing based on
  expiration time or other validity criteria, and automatically refresh them if necessary.

  ## Parameters

    * `provider` - The provider struct containing credentials and configuration

  ## Returns

    * `{:ok, updated_provider}` - Fresh provider data (either original or refreshed)
    * `{:error, reason}` - Failed to refresh or invalid provider data

  """
  @spec ensure(t()) :: {:ok, term()} | {:error, atom()}
  def ensure(provider)
end

defimpl Songy.Boundary.Provider, for: Any do
  @doc """
  Default fallback implementation for unsupported provider types.

  Returns an error indicating that the provider type is not supported.
  """
  def ensure(_provider), do: {:error, :not_supported}
end

defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.Spotify do
  alias Songy.Boundary.Provider.Spotify
  alias Songy.Core.Provider

  @doc """
  Ensures Spotify provider credentials are fresh and valid.

  Delegates to the Spotify boundary module's ensure_provider_data function
  to handle credential refresh logic specific to Spotify's API requirements.

  Only updates the provider if credentials were actually refreshed, preserving
  the original timestamp when credentials remain unchanged.
  """
  def ensure(provider) do
    case Spotify.ensure_provider_data(provider) do
      {:ok, ^provider} ->
        {:ok, provider}

      {:ok, credentials} ->
        {:ok, Provider.Spotify.update(provider, Map.from_struct(credentials))}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defimpl Songy.Boundary.Provider, for: Songy.Core.Provider.Apple do
  alias Songy.Boundary.Provider.Apple
  alias Songy.Core.Provider

  @doc """
  Ensures Apple Music provider is valid.

  Apple Music uses Developer Token which is configured at application level,
  so we only verify that the token is present in config.
  """
  def ensure(_provider) do
    case Apple.access_token() do
      token when is_binary(token) ->
        {:ok, Provider.Apple.new()}

      _ ->
        {:error, :invalid_credentials}
    end
  end
end

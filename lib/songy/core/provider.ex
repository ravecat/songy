defmodule Songy.Core.Provider do
  @moduledoc """
  Provides a common interface for media providers.
  """

  use TypedStruct

  defmodule Behaviour do
    @moduledoc """
    Behaviour for provider-specific metadata enhancement.
    """
    @callback meta(meta :: map()) :: map()
  end

  typedstruct do
    field :id, atom()
    field :meta, map()
  end

  @providers %{
    spotify: __MODULE__.Spotify
  }

  def new(id, meta \\ %{}) do
    enhanced_meta = enhance_meta(id, meta)
    %__MODULE__{id: id, meta: enhanced_meta}
  end

  defp enhance_meta(provider_id, meta) do
    case Map.get(@providers, provider_id) do
      nil -> meta
      provider -> provider.meta(meta)
    end
  end

  defmodule Spotify do
    @moduledoc """
    Spotify provider implementation.
    """
    @behaviour Songy.Core.Provider.Behaviour

    @spotify_token_expires_in 3600

    @impl true
    def meta(credentials) when is_struct(credentials) do
      credentials
      |> Map.from_struct()
      |> extend_with_expires_at()
    end

    @impl true
    def meta(credentials) when is_map(credentials) do
      extend_with_expires_at(credentials)
    end

    defp extend_with_expires_at(credentials_map) do
      expires_at = DateTime.utc_now() |> DateTime.add(@spotify_token_expires_in, :second)

      Map.put(credentials_map, :expires_at, expires_at)
    end
  end
end

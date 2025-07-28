defprotocol Songy.Core.Provider.Credentials do
  @moduledoc """
  Protocol for extracting credentials from various structures for storage in Registry.

  This protocol provides a unified way to extract credential information from provider structures.
  """

  @fallback_to_any true

  @doc """
  Fetches credentials from any structure for storage in Registry.

  Returns a map of credentials if the structure contains valid credential data,
  or nil if no valid credentials are found.
  """
  @spec fetch(t()) :: map() | nil
  def fetch(structure)
end

# Default implementation for Provider structs - extract meta field
defimpl Songy.Core.Provider.Credentials, for: Songy.Core.Provider do
  def fetch(%{meta: meta}) when not is_nil(meta) do
    Map.from_struct(meta)
  end

  def fetch(_), do: nil
end

# Specific implementation for Spotify provider meta
defimpl Songy.Core.Provider.Credentials, for: Songy.Core.Provider.Spotify do
  def fetch(%{access_token: access_token} = credentials) when is_binary(access_token) do
    Map.from_struct(credentials)
  end

  def fetch(_), do: nil
end

# Fallback implementation for any other structure
defimpl Songy.Core.Provider.Credentials, for: Any do
  def fetch(_), do: nil
end

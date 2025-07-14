defmodule Songy.Core.Provider.Behaviour do
  @moduledoc """
  Behaviour for provider-specific metadata enhancement.

  Defines the contract that all provider implementations must follow.
  """

  alias Songy.Core.Provider

  @doc """
  Creates a new provider instance with metadata.
  """
  @callback new(meta :: map()) :: Provider.t()

  @doc """
  Updates provider metadata.
  """
  @callback update(provider :: Provider.t(), attrs :: map()) :: Provider.t()

  @doc """
  Creates a changeset for provider validation.
  """
  @callback changeset(provider :: Provider.t(), attrs :: map()) :: Ecto.Changeset.t()
end

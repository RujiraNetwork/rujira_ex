defmodule Rujira.String do
  @moduledoc """
  Drop-in extension of the standard-library `String`.

  Re-exports the full `String` API and adds Rujira-specific helpers, so a module
  (or a consumer) can `alias Rujira.String` and use it everywhere in place of
  `String`.
  """

  @type t :: Elixir.String.t()
  @type codepoint :: Elixir.String.codepoint()
  @type grapheme :: Elixir.String.grapheme()
  @type pattern :: Elixir.String.pattern()

  # Re-export every (non-deprecated) standard-library String function.
  deprecated = for {{name, arity}, _} <- Elixir.String.__info__(:deprecated), do: {name, arity}

  for {name, arity} <- Elixir.String.__info__(:functions), {name, arity} not in deprecated do
    args = Macro.generate_arguments(arity, __MODULE__)
    defdelegate unquote(name)(unquote_splicing(args)), to: Elixir.String
  end

  # --- Extensions ---

  @doc "Returns `nil` for an absent string (`nil` or `\"\"`), otherwise the value unchanged."
  @spec nil_if_empty(nil | t()) :: t() | nil
  def nil_if_empty(nil), do: nil
  def nil_if_empty(""), do: nil
  def nil_if_empty(value), do: value
end

defmodule Rujira.Test.MockNode do
  @moduledoc "Mock node implementation for tests."
  @behaviour Rujira.Node

  @impl true
  def query(_fun, _request, _opts \\ []) do
    {:error, :not_configured}
  end
end

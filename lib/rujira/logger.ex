defmodule Rujira.Logger do
  @moduledoc false
  require Logger

  @spec info(module(), String.t()) :: :ok
  def info(module, message) do
    Logger.info("#{trim(module)} #{message}")
  end

  @spec error(module(), String.t()) :: :ok
  def error(module, message) do
    Logger.error("#{trim(module)} #{message}")
  end

  @spec debug(module(), String.t()) :: :ok
  def debug(module, message) do
    Logger.debug("#{trim(module)} #{message}")
  end

  @spec warning(module(), String.t()) :: :ok
  def warning(module, message) do
    Logger.warning("#{trim(module)} #{message}")
  end

  defp trim(module) do
    module
    |> to_string()
    |> String.replace_prefix("Elixir.", "")
  end
end

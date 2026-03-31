defmodule Rujira.Logger do
  @moduledoc false
  require Logger

  def info(module, message) do
    Logger.info("#{trim(module)} #{message}")
  end

  def error(module, message) do
    Logger.error("#{trim(module)} #{message}")
  end

  def debug(module, message) do
    Logger.debug("#{trim(module)} #{message}")
  end

  def warning(module, message) do
    Logger.warning("#{trim(module)} #{message}")
  end

  defp trim(module) do
    module
    |> to_string()
    |> String.replace_prefix("Elixir.", "")
  end
end

defmodule Rujira.Node.Subscription.Endpoint do
  @moduledoc """
  A CometBFT websocket endpoint, `ws://host:port/path` or
  `wss://host:port/path`, split into what the connection needs.

  The port defaults to the scheme's (80, 443) and the path to `/websocket`,
  so `ws://thornode:27147` names the same endpoint as
  `ws://thornode:27147/websocket`.
  """

  # --- Struct ---

  defstruct url: nil,
            scheme: :ws,
            host: nil,
            port: 80,
            path: "/websocket"

  @type t :: %__MODULE__{
          url: String.t() | nil,
          scheme: :ws | :wss,
          host: String.t() | nil,
          port: :inet.port_number(),
          path: String.t()
        }

  # --- Construction ---

  @doc """
  Parses `url`. `{:error, {:invalid_url, url}}` for anything that is not a
  `ws://` or `wss://` URL with a host.
  """
  @spec new(term()) :: {:ok, t()} | {:error, {:invalid_url, term()}}
  def new(url) when is_binary(url) do
    case URI.new(url) do
      {:ok, %URI{scheme: scheme, host: host} = uri}
      when scheme in ["ws", "wss"] and is_binary(host) and host != "" ->
        {:ok,
         %__MODULE__{
           url: url,
           scheme: String.to_existing_atom(scheme),
           host: host,
           port: uri.port,
           path: path(uri)
         }}

      _ ->
        {:error, {:invalid_url, url}}
    end
  end

  def new(url), do: {:error, {:invalid_url, url}}

  # --- Calculations ---

  @doc "The HTTP scheme the websocket is upgraded from."
  @spec http_scheme(t()) :: :http | :https
  def http_scheme(%__MODULE__{scheme: :ws}), do: :http
  def http_scheme(%__MODULE__{scheme: :wss}), do: :https

  # --- Private ---

  defp path(%URI{path: path, query: query}) do
    base = if path in [nil, "", "/"], do: "/websocket", else: path
    if query, do: base <> "?" <> query, else: base
  end
end

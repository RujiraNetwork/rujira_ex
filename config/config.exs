import Config

config :rujira_ex,
  prices: Rujira.Prices.Noop

if Mix.env() == :test do
  import_config "test.exs"
end

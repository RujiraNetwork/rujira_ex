import Config

config :rujira_core,
  prices: Rujira.Prices.Noop

if Mix.env() == :test do
  import_config "test.exs"
end

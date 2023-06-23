use Mix.Config

host = System.get_env("PHX_HOST") || "shahmat.org"

config :dojo, DojoWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}],
  url: [host: "shahmat.org"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :info

config :dojo, Dojo.Repo,
  username: "postgres",
  password: "postgres",
  database: "dojo_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

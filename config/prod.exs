use Mix.Config

host = System.get_env("PHX_HOST") || "shahmat.org"

config :dojo, DojoWeb.Endpoint,
  server: true,
  http: [port: {:system, "PORT"}],
  url: [host: {:system, "URL_HOST"}],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

# Do not print debug messages in production
config :logger, level: :info

config :dojo, Dojo.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: Map.fetch!(System.get_env(), "DB_USER"),
  password: Map.fetch!(System.get_env(), "DB_PASS"),
  database: Map.fetch!(System.get_env(), "DB_NAME"),
  hostname: Map.fetch!(System.get_env(), "DB_HOST"),
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :scout,
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :scout_web, ScoutWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ScoutWeb.ErrorHTML, json: ScoutWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Scout.PubSub,
  live_view: [signing_salt: "GhjRd1eC"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :scout, :settings_path, Path.expand("../settings.yaml", __DIR__)

config :bun,
  version: "1.3.4",
  scout_web: [
    args:
      ~w(build assets/js/app.js --outdir=priv/static/assets --external /fonts/* --external /images/*),
    cd: Path.expand("../apps/scout_web", __DIR__)
  ]

config :tailwind,
  version: "4.1.11",
  version_check: false,
  scout_web: [
    args: ~w(--input=assets/css/app.css --output=priv/static/assets/app.css),
    cd: Path.expand("../apps/scout_web", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

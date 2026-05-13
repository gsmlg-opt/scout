import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :scout_web, ScoutWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "m+l4kJqJprbBYRpQxSIalWszrRkfb8JIw1QWvjsK2T2G1QaMWglEaRouP8NFvKk1",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :scout,
       :settings_path,
       Path.expand("../apps/scout_web/test/support/fixtures/settings.yaml", __DIR__)

config :scout_agent, :lightpanda_adapter, Scout.Test.FakeLightpanda

use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ev3, Ev3.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
# config :ev3, Ev3.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "ev3_test",
#   pool: Ecto.Adapters.SQL.Sandbox

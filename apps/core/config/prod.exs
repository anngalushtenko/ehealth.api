use Mix.Config

config :core, Core.ReadRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${READ_DB_NAME}",
  username: "${READ_DB_USER}",
  password: "${READ_DB_PASSWORD}",
  hostname: "${READ_DB_HOST}",
  port: "${READ_DB_PORT}",
  pool_size: "${READ_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}",
  pool_size: "${DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.ReadPRMRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${READ_PRM_DB_NAME}",
  username: "${READ_PRM_DB_USER}",
  password: "${READ_PRM_DB_PASSWORD}",
  hostname: "${READ_PRM_DB_HOST}",
  port: "${READ_PRM_DB_PORT}",
  pool_size: "${READ_PRM_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  types: Core.PRM.PostgresTypes,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.PRMRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${PRM_DB_NAME}",
  username: "${PRM_DB_USER}",
  password: "${PRM_DB_PASSWORD}",
  hostname: "${PRM_DB_HOST}",
  port: "${PRM_DB_PORT}",
  pool_size: "${PRM_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  types: Core.PRM.PostgresTypes,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.FraudRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${FRAUD_DB_NAME}",
  username: "${FRAUD_DB_USER}",
  password: "${FRAUD_DB_PASSWORD}",
  hostname: "${FRAUD_DB_HOST}",
  port: "${FRAUD_DB_PORT}",
  pool_size: "${FRAUD_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  types: Core.Fraud.PostgresTypes,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${EVENT_MANAGER_DB_NAME}",
  username: "${EVENT_MANAGER_DB_USER}",
  password: "${EVENT_MANAGER_DB_PASSWORD}",
  hostname: "${EVENT_MANAGER_DB_HOST}",
  port: "${EVENT_MANAGER_DB_PORT}",
  pool_size: "${EVENT_MANAGER_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :kaffe,
  producer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["deactivate_declaration_events", "merge_legal_entities"]
  ]

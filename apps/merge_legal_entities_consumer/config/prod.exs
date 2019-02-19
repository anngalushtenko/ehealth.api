use Mix.Config

config :kaffe,
  consumer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["merge_legal_entities"],
    consumer_group: "merge_legal_entities_group",
    message_handler: Jobs.LegalEntityMergeJob
  ]

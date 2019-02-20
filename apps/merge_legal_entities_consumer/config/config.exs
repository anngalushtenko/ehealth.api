use Mix.Config

config :merge_legal_entities_consumer,
  kaffe_consumer: [
    endpoints: [localhost: 9092],
    topics: ["merge_legal_entities"],
    consumer_group: "merge_legal_entities_group",
    message_handler: Jobs.LegalEntityMergeJob
  ]

import_config "#{Mix.env()}.exs"

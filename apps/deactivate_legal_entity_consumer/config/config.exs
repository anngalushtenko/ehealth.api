use Mix.Config

config :kaffe,
  consumer: [
    endpoints: [localhost: 9092],
    topics: ["deactivate_legal_entity_event"],
    consumer_group: "deactivate_legal_entity_event_group",
    message_handler: Jobs.LegalEntityDeactivationJob
  ]

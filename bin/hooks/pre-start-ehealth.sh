#!/bin/sh
# `pwd` should be /opt/ehealth
APP_NAME="ehealth"

if [ "${DB_MIGRATE}" == "true" ]; then
  echo "[WARNING] Migrating database!"
  ./bin/$APP_NAME command Elixir.Core.ReleaseTasks migrate
fi;

if [ "${DB_SEED}" == "true" ]; then
  echo "[WARNING] Seeding database!"
  ./bin/$APP_NAME command Elixir.Core.ReleaseTasks seed
fi;

APP_NAME="deactivate_legal_entity_consumer"

if [ "${KAFKA_MIGRATE}" == "true" ] && [ -f "./bin/${APP_NAME}" ]; then
  echo "[WARNING] Migrating kafka topics!"
  ./bin/$APP_NAME command  Elixir.Core.KafkaTasks migrate
fi;

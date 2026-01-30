#!/bin/bash
set -e

echo "Starting Kafka brokers..."
docker exec -d kafka1 /opt/confluent/bin/kafka-server-start /opt/confluent/etc/kafka/kraft/server.properties
docker exec -d kafka2 /opt/confluent/bin/kafka-server-start /opt/confluent/etc/kafka/kraft/server.properties
docker exec -d kafka3 /opt/confluent/bin/kafka-server-start /opt/confluent/etc/kafka/kraft/server.properties

echo "Waiting for Kafka to stabilize..."
sleep 30

echo "Starting Schema Registry..."
docker exec -d schema-registry \
  /opt/confluent/bin/schema-registry-start /opt/confluent/etc/schema-registry/schema-registry.properties

sleep 15

echo "Starting Kafka Connect..."
docker exec -d connect \
  /opt/confluent/bin/connect-distributed /opt/confluent/etc/kafka-connect/connect-distributed.properties

sleep 15

echo "Starting Control Center..."
docker exec -d control-center \
  /opt/confluent/bin/control-center-start /opt/confluent/etc/confluent-control-center/control-center.properties

#!/bin/bash

# Global Configuration Values
HOST=http://host.docker.internal:9093
COLLECTIONS=("curriculum")

# Launch Kafka Connect
/etc/confluent/docker/run &

echo "Waiting for Kafka Connect to start, listening on $HOST"
while true; do
  curl_status=$(curl -s -o /dev/null -w "%{http_code}" $HOST)
  echo "$(date) Kafka Connect listener HTTP state: $curl_status (waiting for 200)"

  if [ "$curl_status" -eq 200 ]; then
    echo "Kafka Connect is ready!"
    break
  fi
  sleep 5
done

echo "Kafka Connect started, Configuring Connectors"

for COLLECTION in "${COLLECTIONS[@]}"; do
  echo "Configuring source connector for collection: $COLLECTION"
  curl -s -X PUT -H "Content-Type:application/json" \
    "$HOST/connectors/source-mongodb-$COLLECTION/config" \
    -d '{
      "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
      "tasks.max": "1",
      "connection.uri": "mongodb://mongodb:27017/?replicaSet=rs0",
      "database": "mentorHub",
      "collection": "'"$COLLECTION"'",
      "output.format.value": "json",
      "output.format.key": "json"
    }'

  echo "Configuring sync connector for collection: $COLLECTION"
  curl -s -X PUT -H "Content-Type:application/json" \
    "$HOST/connectors/sink-elasticsearch-$COLLECTION/config" \
    -d '{
      "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
      "topics": "mentorHub.'$COLLECTION'",
      "connection.url": "http://elasticsearch:9200",
      "type.name": "_doc",
      "key.ignore": true,
      "schema.ignore": true,
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": false
    }'

  echo -e "\nConnector configured for collection: $COLLECTION"
done

# Keep the container alive
sleep infinity
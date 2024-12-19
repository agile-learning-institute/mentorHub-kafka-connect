#!/bin/bash

# Global Configuration Values
HOST=http://localhost:8083
COLLECTIONS=("people")

# Launch Kafka Connect
/etc/confluent/docker/run &

echo "From entrypoint.sh - Waiting for Kafka Connect to start, listening on $HOST"
while true; do
  curl_status=$(curl -s -o /dev/null -w "%{http_code}" $HOST)
  echo "$(date) From entrypoint.sh - Kafka Connect listener HTTP state: $curl_status (waiting for 200)"

  if [ "$curl_status" -eq 200 ]; then
    echo "From entrypoint.sh - Kafka Connect is ready!"
    break
  fi
  sleep 5
done

echo "From entrypoint.sh - Kafka Connect started, Configuring Connectors"

for COLLECTION in "${COLLECTIONS[@]}"; do
  echo "From entrypoint.sh - Configuring source connector for collection: $COLLECTION"
  curl -s -X PUT -H "Content-Type:application/json" \
    "$HOST/connectors/source-mongodb-$COLLECTION/config" \
    -d '{
      "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
      "tasks.max": "1",
      "connection.uri": "mongodb://mongodb:27017/?replicaSet=rs0",
      "database": "mentorHub",
      "collection": "'"$COLLECTION"'",
      "output.format.value": "json"
    }'

  echo "From entrypoint.sh - Configuring sink connector for collection: $COLLECTION"
  curl -s -X PUT -H "Content-Type:application/json" \
    "$HOST/connectors/sink-elasticsearch-$COLLECTION/config" \
    -d '{
      "connector.class": "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector",
      "tasks.max": "1",
      "topics": "mentorHub.'$COLLECTION'",
      "key.ignore": true,
      "schema.ignore": true,
      "connection.url": "http://elasticsearch:9200",
      "type.name": "_doc",
      "name": "sink-elasticsearch-'$COLLECTION'",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": false,
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": false
    }'

  echo -e "\n- From entrypoint.sh - Connectors configured for collection: $COLLECTION"
done

# Keep the container alive
echo "#############################################################################"
echo "#### From entrypoint.sh - Connector configuration complete, good night!" ####"
echo "#############################################################################"
sleep infinity
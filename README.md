# mentorHub-kafka-connect

This repo builds and publishes a custom Kafka-Connect contaienr with MongoDB and ElasticSearch plug-ins installed, and sources and sink's configured. See [Extending Confluent Images](https://docs.confluent.io/platform/current/installation/docker/development.html#extending-images) for information on how to install plugins. See [Running Kafka Connect in Containers](https://developer.confluent.io/courses/kafka-connect/docker-containers/) for more information about using kafka-connect containers.

## Prerequisites
- [Mentorhub Desktop Edition](https://github.com/agile-learning-institute/mentorHub/blob/main/mentorHub-developer-edition/README.md)

### Optional
- [Kafka Cat (kcat)](https://docs.confluent.io/platform/current/installation/overview.html) to work with kafka topics. ``brew install kcat`` on Mac.

# Contributing
See [entrypoint.sh](./entrypoint.sh) for connector configuration information. 

## Build and test the Container Locally
```sh
make container
```
NOTE: This script does ``mh down`` and then builds the container and then starts the needed containers with ``mh up kafka-connect``

Once the container is running you can use the kafka-cat Rest API to interact with the connectors.

### Get a list of Connectors
```bash
curl http://localhost:9093/connectors | jq
```

## Check the status of a connector
```bash
curl http://localhost:9093/connectors/<connector name>/status | jq
```

## Get the configuration of a connector
```bash
curl http://localhost:9093/connectors/<connector name>/config | jq
```

### (Re)Configure a Connector
```bash
curl -s -X PUT -H "Content-Type:application/json" \
    http://localhost:9093/connectors/<connector name>/config \
    -d '{
        "connector.class": "<connector class name>",
        "<option>"       : "<additional connector specific values>",
    }'
```
See [entrypoint.sh](./entrypoint.sh) for details about the mongo source and elasticsearch sync connectors. 

### Pause a Connector
```bash
curl --request PUT 'http://localhost:9093/connectors/<connector name>/pause'
```

### Resume a Connector
```bash
curl --request PUT 'http://localhost:9093/connectors/<connector name>/resume'
```

### Delete a Connector
```bash
curl --request DELETE 'http://localhost:9093/connectors/<connector name>'
```

## Using kcat
You may want to monitor traffic on a topic in the kafka broker. You can use kafka cat (kcat)

### kcat List Topics 
```bash
kcat -b localhost:9092 -L
```

### kcat Publish an event
```bash
cat ./<data>.json | kcat -b localhost:9092 -t <topic> -P
```

# Observability and CI/CD considerations
[GitHub Actions](./.github/workflows/docker-push.yml) are responsible for publishing a public container image.

# Testing

After using the commands above to build the container, you can watch the docker logs of the contaienr with 
```bash
docker logs mentorhub-kafka-connect-1 -f
```

Then open another terminal window and watch the topic ``mentorHub.curriculum``
```bash
kcat -b localhost:9092 -t mentorHub.curriculum -o end -C
```

Now open Mongo Compass, and connect to the database with the connection string ``mongodb://mongodb:27017/?replicaSet=rs0``, select the ``mentorHub`` database, and the ``curriculum`` collection, and click on "Add Data", "Insert Document" and then add the following text after the ``_id`` property, before the closing ``}``

```json
,
        "completed": [],
        "now": [],
        "next": [],
        "later": [
            {"$oid": "999900000000000000000000"},
            {"$oid": "999900000000000000000001"},
            {"$oid": "999900000000000000000003"}
        ],
        "lastSaved": {
            "atTime": {"$date": "2024-02-27T18:17:58"},
            "byUser": {"$oid": "aaaa00000000000000000001"},
            "fromIp": "192.168.1.3",
            "correlationId": "ae078031-7de2-4519-bcbe-fbd5e72b69d3"
        }
```

You should see the source log the change, kcat shoudld show the event, and the logs will probably show an error when the sink connector trys to process the event. 
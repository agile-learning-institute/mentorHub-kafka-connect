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

### Get a list of installed plugins
```bash
curl --request GET 'http://localhost:9093/connector-plugins' | jq
```

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

# Testing Access from the command line

### Test access to the MongoDB

#### From outside of Docker
```sh
curl -v localhost:27017
```

#### From the Kafka-Connect container
```sh
docker exec -it mentorhub-kafka-connect-1 curl -v mongodb:27017
```

#### Expected Reply
```
* Host {hostname}:27017 was resolved.
....
It looks like you are trying to access MongoDB over HTTP on the native driver port.
```

### Test access to the ElasticSearch Database

#### From outside of Docker
```sh
curl -v localhost:9200
```

#### From the Kafka-Connect container
```sh
docker exec -it mentorhub-kafka-connect-1 curl -v elasticsearch:9200
```

#### Expected Reply
```sh
* Host {hostname}:9200 was resolved.
....
* Connection #0 to host localhost left intact
```

### Test access to the Kafka Event Bus

#### From outside of Docker
First write a test message to a topic. 
```sh
echo "test message" | kcat -P -b localhost:9092 -t test-topic
```

Then you can use kcat to read that topic
```sh
kcat -C -b localhost:9092 -t test-topic -o beginning -e
```

#### From the Kafka-Connect container
Since kcat is on installed in the container we will use the kafka-console-consumer utility.
```sh
docker exec -it mentorhub-kafka-connect-1 kafka-console-consumer --bootstrap-server kafka:19092 --topic test-topic --from-beginning --max-messages 1
```

#### Expected Reply
You should see the test message that was previously placed on the topic.

### Test access to the Kafka-Connect Server

#### From outside of Docker
```sh
curl localhost:9093/connectors
```

#### From the Kafka-Connect container
```sh
docker exec -it mentorhub-kafka-connect-1 curl localhost:8083/connectors
```

#### Expected Reply
```
[]
```
Or a list of connectors if they have been configured

# Testing Connectors

After using the commands above to build the container, you can watch the docker logs of the container with 
### Review the logs of the kafka-connect container
```bash
mh tail kafka-connect
```
NOTE: This will tail the active log, page-up/down keys should work, ctrl-c to exit 

Then open another terminal window and watch the topic ``mentorHub.curriculum``
```bash
kcat -b localhost:9092 -t mentorHub.curriculum -o end -C
```
NOTE: This will tail the topic showing new messages as they arrive, ctrl-c to exit

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

You should see the source log the change, kcat should show the event, and the logs will probably show an error when the sink connector try's to process the event. 
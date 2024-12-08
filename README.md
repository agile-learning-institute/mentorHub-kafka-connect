# mentorHub-kafka-connect

This repo builds and publishes a custom Kafka-Connect container with MongoDB and ElasticSearch plug-ins installed, and sources and sinks configured. See [Extending Confluent Images](https://docs.confluent.io/platform/current/installation/docker/development.html#extending-images) for information on how to install plugins. See [Running Kafka Connect in Containers](https://developer.confluent.io/courses/kafka-connect/docker-containers/) for more information about using kafka-connect containers.

Table of Contents
- [Contributing](#contributing)
- [Using the Kafka-Connect REST API](#using-the-kafka-connect-rest-api)
- [Using Kafka Cat (kcat) with topics](#using-kcat-to-interact-with-kafka-topics)
- [Testing Connectivity](#testing-connectivity)
- [Observability and CI/CD Notes](#observability-and-cicd-considerations)
- [Current State - Testing Connectors](#testing-connectors)

---

# Contributing

## Prerequisites
- [Mentorhub Desktop Edition](https://github.com/agile-learning-institute/mentorHub/blob/main/mentorHub-developer-edition/README.md)

### Optional
- [Kafka Cat (kcat)](https://docs.confluent.io/platform/current/installation/overview.html) to work with kafka topics. ``brew install kcat`` on Mac.

## Code
This repo creates a custom version of the confluent kafka-connect official container, using the [Dockerfile](./Dockerfile) to install the needed connector plugins and install the entrypoint.sh script. The [entrypoint.sh](./entrypoint.sh) script starts the connector server, then waits for it to be healthy, and then uses curl commands to configures the connectors. 

## Build and test the Container Locally
```sh
make container
```
NOTE: This script does ``mh down`` and then builds the container and then starts the needed backing service containers with ``mh up kafka-connect`` and tails the kafka-connect logs. Ctrl-c to exit the tail.

Once the container is running you can use Kafka-Connect REST API to interact with the connectors, and use kcat to interact with the Kafka broker. If you are troubleshooting see [Testing Connectivity](#testing-connectivity) and [Current State]()

---

# Using the kafka-connect REST API.

## Get a list of installed plugins
```bash
curl --request GET 'http://localhost:9093/connector-plugins' | jq
```

## Get a list of Connectors
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

## (Re)Configure a Connector
```bash
curl -s -X PUT -H "Content-Type:application/json" \
    http://localhost:9093/connectors/<connector name>/config \
    -d '{
        "connector.class": "<connector class name>",
        "<option>"       : "<additional connector specific values>",
    }'
```
See [entrypoint.sh](./entrypoint.sh) for details about the mongo source and elasticsearch sync connectors. 

## Pause a Connector
```bash
curl --request PUT 'http://localhost:9093/connectors/<connector name>/pause'
```

## Resume a Connector
```bash
curl --request PUT 'http://localhost:9093/connectors/<connector name>/resume'
```

## Delete a Connector
```bash
curl --request DELETE 'http://localhost:9093/connectors/<connector name>'
```

---

# Using kcat to interact with kafka topics
You may want to monitor traffic on a topic in the kafka broker. You can use kafka cat (kcat)

## kcat List Topics 
```bash
kcat -b localhost:9092 -L
```
You can use the topic names listed with the below commands

## kcat Publish an event
```bash
cat ./<data>.json | kcat -b localhost:9092 -t <topic.name> -P
```

## kcat tail a topic
```bash
kcat -b localhost:9092 -t <topic.name> -o end -C
```
NOTE: This will tail the topic showing new messages as they arrive, ctrl-c to exit

---

# Testing Connectivity
The Kafka-Connect container must successfully connect to the kafka broker, mongodb database, and elasticsearch database in order to function. You can use the following tests to check that the proper network connectivity is in place. 

## Test access to the MongoDB

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

## Test access to the ElasticSearch Database

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

## Test access to the Kafka Event Bus

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

## Test access to the Kafka-Connect Server

#### From outside of Docker
```sh
curl localhost:9093/connectors
```

#### From the Kafka-Connect container
```sh
docker exec -it mentorhub-kafka-connect-1 curl localhost:9093/connectors
```

#### Expected Reply
```
[]
```
Or a list of connectors if they have been configured

---

# Observability and CI/CD considerations
[GitHub Actions](./.github/workflows/docker-push.yml) are responsible for publishing a public container image.


# Current State
All of the infrastructure appears to be working correctly, with a source and sink being configured. The source does see a new record added to the mongo database, and the sink does try to process the event, however the sync connector fails. Transformations are needed to make the sink connector function correctly. I want to keep the default Source configuration without any transformations because there may be future consumers that will want that event stream as is. 

To re-create the current progress, use the commands above to build and run the container. If it's already running you can watch the docker logs of the container with 
### Review the logs of the kafka-connect container
```bash
mh tail kafka-connect
```
NOTE: This will tail the active log, page-up/down keys should work, ctrl-c to exit after your done testing.

Then open another terminal window and watch the topic ``mentorHub.curriculum``
```bash
kcat -b localhost:9092 -t mentorHub.curriculum -o end -C
```
NOTE: This will tail the topic showing new messages as they arrive, ctrl-c to exit when your done.

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

You should see the source log the change, kcat should show the event on the topic, and the logs then show an error when the sink connector try's to process the event. 
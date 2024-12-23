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


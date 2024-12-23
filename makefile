# Makefile

.PHONY: container update-sink update-source list watch test reset status 

# Build and run the Docker container
container:
	mh down
	docker build --tag ghcr.io/agile-learning-institute/mentorhub-kafka-connect:latest .
	mh up kafka-connect,person-api
	mh tail kafka-connect

update-sink:
	curl --request DELETE 'http://localhost:9093/connectors/sink-elasticsearch-people'                                                                      
	curl -X PUT -H "Content-Type:application/json" http://localhost:9093/connectors/sink-elasticsearch-people/config -d @sink.json
	curl http://localhost:9093/connectors/sink-elasticsearch-people/status | jq

update-source:
	curl --request DELETE 'http://localhost:9093/connectors/source-mongodb-people'                                                                      
	curl -X PUT -H "Content-Type:application/json" http://localhost:9093/connectors/source-mongodb-people/config -d @source.json
	curl http://localhost:9093/connectors/source-mongodb-people/status | jq

list:
	curl http://localhost:9093/connectors | jq

watch:
	kcat -b localhost:9092 -t mentorHub.people -o end -C

test:
	curl -X POST http://localhost:8082/api/person/ -d '{"userName":"Foo", "description":"Some short description"}' | jq

reset:
	docker rm -f mentorhub-mongodb-1
	mh up mongoonly
	docker container start mentorhub-initialize-mongodb-1

status:	
	curl http://localhost:9093/connectors/sink-elasticsearch-people/status | jq
	curl http://localhost:9093/connectors/source-mongodb-people/status | jq

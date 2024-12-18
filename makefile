# Makefile

.PHONY: container update list status test

# Build and run the Docker container
container:
	mh down
	docker build --tag ghcr.io/agile-learning-institute/mentorhub-kafka-connect:latest .
	mh up kafka-connect,person-api
	mh tail kafka-connect

update:
	curl --request DELETE 'http://localhost:9093/connectors/sink-elasticsearch-people'                                                                      
	curl -X PUT -H "Content-Type:application/json" http://localhost:9093/connectors/sink-elasticsearch-people/config -d @sink.json
	curl http://localhost:9093/connectors/sink-elasticsearch-people/status | jq

list:
	curl http://localhost:9093/connectors | jq

test:
	curl -X POST http://localhost:8082/api/person/ -d '{"userName":"Foo", "description":"Some short description"}' | jq

status:	
	curl http://localhost:9093/connectors/sink-elasticsearch-people/status | jq

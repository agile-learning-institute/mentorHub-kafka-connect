# Makefile

.PHONY: container

# Build and run the Docker container
container:
	mh down
	docker build --tag ghcr.io/agile-learning-institute/mentorhub-kafka-connect:latest .
	mh up kafka-connect
	mh tail kafka-connect

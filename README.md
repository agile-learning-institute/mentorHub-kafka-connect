# mentorHub-kafka-connect

Custom Kafka-Connect contaienr with MongoDB and ElasticSearch plug-ins installed. See [Extending Confluent Images](https://docs.confluent.io/platform/current/installation/docker/development.html#extending-images) for information on how to install plugins. 

### Build Container Locally
```sh
make container
```

[GitHub Actions](./.github/workflows/docker-push.yml) are responsible for publishing the public container image.


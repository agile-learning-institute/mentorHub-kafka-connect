FROM confluentinc/cp-server-connect-base:7.7.1

RUN    confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:latest \
    && confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest

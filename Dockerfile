FROM confluentinc/cp-server-connect-base:7.1.3

# Install required connectors
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:latest 
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:11.1.8
RUN confluent-hub install --no-prompt debezium/debezium-connector-mysql:1.7.1 
RUN confluent-hub install --no-prompt neo4j/kafka-connect-neo4j:2.0.1
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.3.3

# Copy the entrypoint script to the container and set proper permissions
COPY entrypoint.sh /entrypoint.sh

# Use the entrypoint script as the container's entrypoint
ENTRYPOINT ["/entrypoint.sh"]
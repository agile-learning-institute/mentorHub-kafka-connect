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

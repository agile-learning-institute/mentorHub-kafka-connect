# Using kcat to interact with kafka topics

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


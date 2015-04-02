# Node.js + Express + Kafka + Mongodb

## Environment setup with [Docker](https://www.docker.io/)

### Node

- Install [node v0.12](http://nodejs.org/download/)

- Install node-foreman `$ npm install -g foreman`

- run `$ npm install`


### Kafka

If you are using a Mac follow the instructions [here](https://docs.docker.com/installation/mac/) to setup a docker environment.

- Install [Docker-Compose](https://docs.docker.com/compose/install/)

- Start the test environment
    - `docker-compose up`  
- Start a kafka shell
    - `./scripts/shells/start-kafka-shell.sh`  
- From within the shell, create a topic
    - `$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper $ZK --topic replicated --replication-factor 2 --partitions 3`

- For more details and troubleshooting see [https://github.com/wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker)


## Running

- `$ nf start`

caveat: between restart, wait for a similar message before starting to avoid consumer connection error described in https://github.com/SOHU-Co/kafka-node/issues/90

(we set up `sessionTimeout: 1000` in the consumer ti make it less painful to test, this value shoued be increased in production to avoid zookeeper timeouts due to network glitches)

```
zookeeper_1 | 2015-02-19 11:28:58,000 [myid:] - INFO  [SessionTracker:ZooKeeperServer@347] - Expiring session 0x14ba15e9c0f0024, timeout of 4000ms exceeded
zookeeper_1 | 2015-02-19 11:28:58,002 [myid:] - INFO  [ProcessThread(sid:0 cport:-1)::PrepRequestProcessor@494] - Processed session termination for sessionid: 0x14ba15e9c0f0024
```

## Test Requests

- to send messages: `$ curl -X POST http://localhost:3001/`

- to read  last received message by worker: `$ curl http://localhost:3001/`

- to perform apache benchmark `./scripts/tests/benchmark.sh`

## Checking Data

- to open the running mongo container: `./scripts/shells/start-mongo-shell.sh`  

- point to the kafka db: `use kafka`

- list the documents: `db.kafka.find().pretty()`

## References

- [wurstmeister/storm-kafka-0.8-plus-test](https://github.com/wurstmeister/storm-kafka-0.8-plus-test)
- [SOHU-Co/kafka-node](https://github.com/SOHU-Co/kafka-node/)
- [Running Multibroker Clusters on a Single Node](http://www.michael-noll.com/blog/2013/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/)

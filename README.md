# [Node.js](https://nodejs.org/) + [ExpressJS](http://expressjs.com/) + [Kafka](https://kafka.apache.org/) + [Mongodb](https://www.mongodb.org/)

<a name="TableOfContents"></a>
##Table of Contents

1. <a href="#Setup">Setup</a>
  * <a href="#SetupZookeeper">Zookeeper</a>
  * <a href="#SetupKafka">Kafka</a>
  * <a href="#SetupMongo">MongoDB</a>
  * <a href="#SetupNode">Node</a>
2. <a href="#Running">Running</a>
3. <a href="#TestRequests">Test Requests</a>
4. <a href="#SeeingData">Seeing Data</a>
5. <a href="#ResetingData">Reseting Data</a>
6. <a href="#MultibrokerConfiguration">Multibroker Configuration</a>
7. <a href="#Backup">Backup Strategies</a>
8. <a href="#TroubleShooting">Trouble Shooting</a>
  * <a href="#TroubleShootingZK">Zookeeper</a>
  * <a href="#TroubleShootingKafka">Kafka</a>
  * <a href="#TroubleShootingOthers">Others</a>
8. <a href="#DEVSTAGPROD">Multiple Environments</a>
9. <a href="#References">References</a>


<a name="Setup"></a>
## Setup

<a name="SetupZookeeper"></a>
### Zookeeper

- `bin/zookeeper-server-start.hs config/zookeeper1.properties`  

This will start a Zookeeper instance running on `localhost:2181`

<a name="SetupKafka"></a>
### Kafka

- From another terminal window, start a kafka broker instance:  
    - `bin/kafka-server-start.sh config/server1.properties`

- From another terminal window, create a topic
    - `bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic test --replication-factor 1 --partitions 3`  

```
Created topic "test".
```

- And then describe this topic's configuration  
    - `bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic test`  

```
Topic:test	PartitionCount:3	ReplicationFactor:1	Configs:
	Topic: test	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
	Topic: test	Partition: 1	Leader: 0	Replicas: 0	Isr: 0
	Topic: test	Partition: 2	Leader: 0	Replicas: 0	Isr: 0

```
<a name="SetupMongo"></a>
### MongoDB

- Install [MongoDb](http://docs.mongodb.org/v2.6/installation/)

- Start a mongo instance: `mongod`

<a name="SetupNode"></a>
### Node

- Install [node v0.12](http://nodejs.org/download/)

- Install node-foreman `$ npm install -g foreman`

- run `$ npm install`

-----
<a name="Running"></a>
## Running

- `$ nf start`


wait for these two outputs:
```
web.1    |  KAFKA producer ready
worker.1 |  KAKFA consumer rebalanced
```

caveat: between restart, wait for a similar message in zookeeper window before starting to avoid consumer connection error described in https://github.com/SOHU-Co/kafka-node/issues/90

(we set up `sessionTimeout: 1000` in the consumer ti make it less painful to test, this value shoued be increased in production to avoid zookeeper timeouts due to network glitches)

```
INFO  [SessionTracker:ZooKeeperServer@347] - Expiring session 0x14ba15e9c0f0024, timeout of 4000ms exceeded
INFO  [ProcessThread(sid:0 cport:-1)::PrepRequestProcessor@494] - Processed session termination for sessionid: 0x14ba15e9c0f0024
```
-----
<a name="TestRequests"></a>
## Test Requests

- to send messages: `$ curl -X POST http://localhost:3001/` or `$ curl -X POST http://127.0.0.1:3001/` if curl is having any [trouble with localhost](http://superuser.com/questions/830920/curl-local-host-names-on-mac-os-x-yosemite)

- to perform apache benchmark `./scripts/tests/benchmark.sh`

-----
<a name="SeeingData"></a>
## Seeing Data

- to read last received message by worker: `$ curl http://localhost:3001/`

- to list how many messages each partition received: `$ curl http://localhost:3001/partitions`

Optionally you can see straight from mongo

- open a new terminal window and run: `mongo`  

- point to the kafka db: `use kafka`

- list the documents: `db.kafka.find().pretty()`


Or make all these requests from [Postman](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en). Just use the collection at `postman` directory.

-----
<a name="ResetingData"></a>
## Reseting Data

To reset all kafka and zookeeper information, just delete `tmp` and `logs` directories.

-----
<a name="MultibrokerConfiguration"></a>
## Multibroker Configuration

As you maybe notice in SETUP steps, we instantiated zookeeper and kafka with `zookeeper1.properties` and `server1.properties` respectively. This was not just for beautiful names.

This project is setted up to work with two ZK instances and three kafka brokers. Let's see how this works:

- Stop nf processes

- Start the others brokers
  - `bin/kafka-server-start.sh config/server2.properties`
  - `bin/kafka-server-start.sh config/server3.properties`

- create a new topic with replication factor = number of brokers:
  - `bin/kafka-topics.sh --zookeeper localhost:2181 --create --topic test-replicated --replication-factor 3 --partitions 8`

- describe the topic
  - `bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic test-replicated`

```
Topic:test-replicated	PartitionCount:8	ReplicationFactor:3	Configs:
	Topic: test-replicated	Partition: 0	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: test-replicated	Partition: 1	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
	Topic: test-replicated	Partition: 2	Leader: 0	Replicas: 0,1,2	Isr: 0,1,2
	Topic: test-replicated	Partition: 3	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: test-replicated	Partition: 4	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	Topic: test-replicated	Partition: 5	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
	Topic: test-replicated	Partition: 6	Leader: 1	Replicas: 1,2,0	Isr: 1,2,0
	Topic: test-replicated	Partition: 7	Leader: 2	Replicas: 2,0,1	Isr: 2,0,1
```

-----
<a name="Backup"></a>
## Possible Backup Strategies

Take a better look at [SECOR - Persisting kafka logs to Amazon S3](https://github.com/pinterest/secor)  
[This conversation](http://grokbase.com/t/kafka/users/136eqq0xdp/0-8-backup-strategy-anyone) also seems to be good

-----
<a name="TroubleShooting"></a>
## Trouble Shooting?

<a name="TroubleShootingZK"></a>
### Zookeeper

If you see logs like:  
`worker.1 |  KAFKA consumer error:Exception: NO_NODE[-101]`  
This means that the node doesn't exists in the zookeeper.

or Logs like (on zookeeper terminal):  
`Error:KeeperErrorCode = NodeExists for /consumers/worker.js`
This one means that the current consumer you are trying to create already exists in the cluster.

Well, I still haven't figured it out yet what those thinks actually mean and what to do with them.
You can try to figure it out by [this issue on kafka-node](https://github.com/SOHU-Co/kafka-node/issues/90), [this article on ZK ephemeral nodes](https://www.box.com/blog/a-gotcha-when-using-zookeeper-ephemeral-nodes/), [Zookeeper documentation](http://zookeeper.apache.org/doc/r3.3.2/api/org/apache/zookeeper/ZooKeeper.html).

Normally restarting the consumers work.

<a name="TroubleShootingKafka"></a>
### Kafka

If for any reason you close a terminal window <kbd>cmd</kbd>+<kbd>W</kbd> without terminating the kafka broker, and when you try to run it again it tells you that this port is already in use, you can shut down all brokers with:

- `bin/kafka-server-stop.sh`

<a name="TroubleShootingOthers"></a>
### Others

It's always a good idea to look at the [Kafka FAQ](https://cwiki.apache.org/confluence/display/KAFKA/FAQ)

------
<a name="DEVSTAGPROD"></a>
## Multiple environments (dev, stag, prod)

There's a npm package used on kafka-node let us see what is happening on the zookeeper.

- run `node node_modules/kafka-node/node_modules/node-zookeeper-client/examples/list.js localhost:2181 /`  

This means that we are asking zookeeper at localhost:2181 to list all node children from path `/` (root).
```
Connected to ZooKeeper.
Children of node: / are: ["controller_epoch","controller","brokers","zookeeper","admin","consumers","config"].
```

From this point you can explore the zookeeper and understand a little better how it works:  
- `node node_modules/kafka-node/node_modules/node-zookeeper-client/examples/list.js localhost:2181 /consumers`

```
Connected to ZooKeeper.
Children of node: /consumers are: ["worker.js","worker.js_0"].
```
And from [Zookeeper documentation](http://zookeeper.apache.org/doc/r3.3.2/api/org/apache/zookeeper/ZooKeeper.html) you can see that when connecting to a ZK you can specify a root path that this ZK will put the data you pass to the instance. When putting the same URL on the brokers (`zookeeper.connect`) `server.properties`, You can specify an "app" encapsulated in the zookeeper. This way you can create different clusters in the same zookeeper and infrastructure, for exaple DEV and STAG environments!!


-----
<a name="References"></a>
## References

- [wurstmeister/storm-kafka-0.8-plus-test](https://github.com/wurstmeister/storm-kafka-0.8-plus-test)
- [SOHU-Co/kafka-node](https://github.com/SOHU-Co/kafka-node/)
- [Running Multibroker Clusters on a Single Node](http://www.michael-noll.com/blog/2013/03/13/running-a-multi-broker-apache-kafka-cluster-on-a-single-node/)
- [Operational Problems with ZK](http://marcin.cylke.com.pl/blog/2013/03/21/zookeeper-tips/)
- [Semantic Partioning](http://mail-archives.apache.org/mod_mbox/kafka-users/201308.mbox/%3CCAPihp9nD7jS0sp1qvfzommFAALiMVuaaW0vv1z547nhLRWxsYA@mail.gmail.com%3E)
- [Introduction to kafka](http://kafka.apache.org/documentation.html#introduction)
- [Jumpstart kafka 0.8 with scala 2.9.2 on Mac OSX](http://dennyglee.com/2013/06/05/jump-start-on-apache-kafka-0-8-with-scala-2-9-2-on-mac-osx/)
- [VIDEO - Apache kafka tutorial](https://www.youtube.com/watch?v=7TZiN521FQA)
- [Github - kafka-nodejs](https://github.com/zubayr/kafka-nodejs)
- [kafka configurations](https://kafka.apache.org/08/configuration.html)
- [kafka mirrormaker](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330)


<a href="#TableOfContents">Go up again :)</a>

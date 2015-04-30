var express = require('express'),
    moment = require('moment-timezone'),
    app = express(),

    // database
    mongojs = require('mongojs'),
    db = mongojs(process.env.MONGO_URL || 'localhost:27017/kafka'),

    // kafka
    kafka = require('kafka-node'),
    client = new kafka.Client(process.env.KAFKA_URL || '130.211.119.190:2181/dev', process.env.KAFKA_PRODUCER_ID || 'kafka-node-client-producer',  {
      sessionTimeout: 1000 // this is just to enable multiple restarts in debug and avoid https://github.com/SOHU-Co/kafka-node/issues/90 - should be removed in PRD
    }),
    HighLevelProducer = kafka.HighLevelProducer,
    producer = new HighLevelProducer(client);

// Express setup
app.listen(process.env.PORT || 3001);
console.log('Server Listening on port: ' + (process.env.PORT || 3001));

app.post('/', function(req, res) {

  var timestamp = moment().unix();

  // sends value to kafka
  var topicMessage = {
    topic: 'dev',
    messages: [
      // all messages must be string :S
      JSON.stringify({ timestamp: timestamp, rnd: Math.random() })
    ]
  };

  var payload = [ topicMessage ];

  producer.send(payload, function (err, data) {
    if (err) {
      res.send(500, err);
    } else {
      res.json(200, {timestamp: timestamp});
    }
  });

});

app.get('/', function(req, res) {
  db.collection('kafka').find({_id: 123456}, function(err, data) {
    if(err) {
      res.send(500, err);
    } else if (!data) {
      res.send(404, 'nothing found...');
    } else {
      res.json(200, data);
    }
  });
})

app.get('/partitions', function (req, res) {
  db.collection('kafka').find({_id:  /partition/ }, function (err, data) {
    if(err) {
      res.send(500, err);
    } else if (!data) {
      res.send(404, 'nothing found...');
    } else {
      res.json(200, data);
    }
  });
})


// Kafka events
producer.on('ready', function () {
  console.log('KAFKA producer ready');
});

producer.on('error', function (err) {
  console.log('KAFKA producer error:' + err);
})

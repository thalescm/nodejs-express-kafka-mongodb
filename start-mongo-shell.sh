#!/bin/bash
docker exec -it $(docker ps | grep mongo:2.6.7 | cut -f 1 -d " ") mongo

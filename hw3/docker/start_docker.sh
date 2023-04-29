#!/bin/bash

docker compose -f docker-compose-network.yml -f docker-compose-cluster.yml\
 -f docker-compose-standalone.yml -f docker-compose-insight.yml up --remove-orphans -d
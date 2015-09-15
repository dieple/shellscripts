#!/bin/bash

#install docker daemon/engine, and run it
sudo yum -y update && \
sudo yum -y install docker docker-registry  && \
sudo systemctl enable docker.service && \
sudo systemctl start docker.service

# build the docker container using the Dockerfile in the current directory
# sudo docker build -t dieple/devops .

# now download the ready made docker image from my repository
sudo docker pull dieple/devops

# now download the ready made docker image of cassandra DB from my repository
sudo docker pull dieple/apidocker-cassandra

# now run the downloaded container ( make sure /apps/sandboxes exists in the host machine)
sudo docker run --detach -v /apps/sandboxes:/apps/sandboxes -p 8080:8080 -p 3000:3000 -p 3001:3001 -p 4022:22 -t dieple/devops

# Now run the cassandra DB container
sudo docker run --detach dieple/apidocker-cassandra


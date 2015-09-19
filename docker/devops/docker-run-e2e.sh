#!/bin/bash

sudo docker run -v ~/apps/docker/e2e:/apps/docker/e2e -p 8080:8080 -p 9000:9000 -p 35729:35729 -p 4022:22  -p 5672:5672 -p 15672:15672 -p 3306:3306 -t dieple/e2edocker

#cat ~/.ssh/id_rsa.pub | ssh -p 4022 osdba@localhost 'mkdir ~/.ssh && cat >> ~/.ssh/authorized_keys'

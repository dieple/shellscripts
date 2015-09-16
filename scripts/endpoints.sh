#!/bin/bash

TEMP=/tmp/$$.temp
TOKEN=""

curl \
--header "Content-Type:application/json" \
--header "Accept:application/json" \
--request POST \
--data "{\"username\":\"jack123\",\"password\":\"secret\"}" \
http://lucas-api-dev.elasticbeanstalk.com/authenticate > $TEMP 2>/dev/null

#http://localhost:8080/lucas-api/authenticate > $TEMP 2>/dev/null


TOKEN=`awk -F ":" '{print $7}' $TEMP | awk -F"," '{print $1}' | awk -F\" '{print $2}'`

curl \
-u jack123:secret \
--header "Content-Type:application/json" \
--header "Authentication-token:$TOKEN" \
--header "Accept:application/json" \
--request POST \
--data "{ \"pageNumber\":\"0\", \"pageSize\":\"300\", \"sortMap\":{}, \"searchMap\":{\"groupName\":{\"filterType\":\"ALPHANUMERIC\",\"values\":[\"%%\"] }, \"userCount\":{\"filterType\":\"NUMERIC\",\"values\":[\">=0\"]}}}" \
http://lucas-api-dev.elasticbeanstalk.com/groups/grouplist/search

#http://localhost:8080/lucas-api/groups/grouplist/search
echo ""
rm $TEMP

#!/bin/bash

INFLUXDB_HOST=${INFLUXDB_HOST:-influxdb}

# give time to influxdb to be up
sleep 2

curl -I $INFLUXDB_HOST:8083 2>/dev/null | grep -q "HTTP/1.1 200 OK"
if [[ $? -ne 0 ]]; then
  echo "Influxdb:8083 failed"
  curl -I $INFLUXDB_HOST:8083
  exit 1
fi
curl -I $INFLUXDB_HOST:8086/ping 2>/dev/null | grep -q "HTTP/1.1 204 No Content"
if [[ $? -ne 0 ]]; then
  echo "Influxdb:8086 ping failed"
  exit 1
fi

# give time to telegraf to send data
sleep 2
r=$(curl -GET "http://$INFLUXDB_HOST:8086/query?pretty=true" --data-urlencode "db=telegraf" --data-urlencode "q=SELECT usage_total FROM docker_container_cpu limit 1" 2>/dev/null | jq -r '.results[0] | has("series")')
if [[ "x$r" != "xtrue" ]]; then
  echo "Influxdb telegraf db has no docker_container_cpu measurements ($r)"
  exit 1
fi

echo "all tests are OK"

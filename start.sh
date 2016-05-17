#!/bin/sh

#display env. variables
echo ---------------------------------------------------------------------------
echo "CONSUL: "$CONSUL
if [ -z "$CONSUL" ]; then
  exec /run.sh
else
  #update containerpilot conffile
  sed -i "s/\[consul\]/$CONSUL/g" /etc/containerpilot.json
  echo ---------------------------------------------------------------------------
  echo containerPilot conffile
  cat /etc/containerpilot.json
  echo ---------------------------------------------------------------------------
  exec /bin/containerpilot /run.sh
fi
#!/bin/bash

CONFIG_FILE="/etc/influxdb/config.toml"
CONFIG_OVERRIDE_FILE="/etc/base-config/influxdb/config.toml"
CONFIG_EXTRA_DIR="/etc/extra-config/influxdb/"
INFLUX_HOST="localhost"
INFLUX_API_PORT="8086"
API_URL="http://${INFLUX_HOST}:${INFLUX_API_PORT}"
ADMIN=${ADMIN_USER:-root}
PASS=${INFLUXDB_INIT_PWD:-root}
PILOT="/bin/amp-pilot"

wait_for_start_of_influxdb(){
    #wait for the startup of influxdb
    local retry=0
    while ! curl ${API_URL}/ping 2>/dev/null; do
        retry=$((retry+1))
        if [ $retry -gt 15 ]; then
            echo "\nERROR: unable to start grafana"
            exit 1
        fi
        echo -n "."
        sleep 3
    done
    echo "Influxdb is available"
}

# set env variables for configuration template

# max-open-shards
CONFIG_MAX_OPEN_SHARDS="$(ulimit -n)"
export CONFIG_MAX_OPEN_SHARDS

# hostname
# Configure InfluxDB Cluster
if [ -n "${FORCE_HOSTNAME}" ]; then
    if [ "${FORCE_HOSTNAME}" = "auto" ]; then
        #set hostname with IPv4 eth0
        HOSTIPNAME=$(ip a show dev eth0 | grep inet | grep eth0 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
        CONFIG_HOSTNAME="$HOSTIPNAME"
    else
        CONFIG_HOSTNAME="$FORCE_HOSTNAME"
    fi
    export CONFIG_HOSTNAME
fi

if [ "${PRE_CREATE_DB}" == "**None**" ]; then
    unset PRE_CREATE_DB
fi

# NOTE: It seems this is not used anymore...
#
# if [ "${SSL_CERT}" == "**None**" ]; then
#     unset SSL_CERT
# fi
#
# if [ "${SSL_SUPPORT}" == "**False**" ]; then
#     unset SSL_SUPPORT
# fi

# Add Graphite support
if [ -n "${GRAPHITE_DB}" ]; then
    echo "GRAPHITE_DB: ${GRAPHITE_DB}"
    CONFIG_GRAPHITE_DATABASE="$GRAPHITE_DB"
    export CONFIG_GRAPHITE_DATABASE
fi

if [ -n "${GRAPHITE_BINDING}" ]; then
    echo "GRAPHITE_BINDING: ${GRAPHITE_BINDING}"
    CONFIG_GRAPHITE_BINDING="$GRAPHITE_BINDING"
    export CONFIG_GRAPHITE_BINDING
fi

if [ -n "${GRAPHITE_PROTOCOL}" ]; then
    echo "GRAPHITE_PROTOCOL: ${GRAPHITE_PROTOCOL}"
    CONFIG_GRAPHITE_PROTOCOL="$GRAPHITE_PROTOCOL"
    export CONFIG_GRAPHITE_PROTOCOL
fi

if [ -n "${GRAPHITE_TEMPLATE}" ]; then
    echo "GRAPHITE_TEMPLATE: ${GRAPHITE_TEMPLATE}"
    CONFIG_GRAPHITE_TEMPLATE="$GRAPHITE_TEMPLATE"
    export CONFIG_GRAPHITE_TEMPLATE
fi

# Add Collectd support
if [ -n "${COLLECTD_DB}" ]; then
    echo "COLLECTD_DB: ${COLLECTD_DB}"
    CONFIG_COLLECTD_DB="$COLLECTD_DB"
    export CONFIG_COLLECTD_DB
fi
if [ -n "${COLLECTD_BINDING}" ]; then
    echo "COLLECTD_BINDING: ${COLLECTD_BINDING}"
    CONFIG_COLLECTD_BINDING="$COLLECTD_BINDING"
    export CONFIG_COLLECTD_BINDING
fi
CONFIG_COLLECTD_RETENTION_POLICY=""
if [ -n "${COLLECTD_RETENTION_POLICY}" ]; then
    echo "COLLECTD_RETENTION_POLICY: ${COLLECTD_RETENTION_POLICY}"
    CONFIG_COLLECTD_RETENTION_POLICY="$COLLECTD_RETENTION_POLICY"
fi
export CONFIG_COLLECTD_RETENTION_POLICY

# Add UDP support
if [ -n "${UDP_DB}" ]; then
    CONFIG_UDP_DB="$UDP_DB"
    export CONFIG_UDP_DB
fi
if [ -n "${UDP_PORT}" ]; then
    CONFIG_UDP_PORT="$UDP_PORT"
    export CONFIG_UDP_PORT
fi

if [ -f "${CONFIG_OVERRIDE_FILE}" ]; then
  echo "INFO - Override InfluxDB configuration file"
  cp "${CONFIG_OVERRIDE_FILE}" "${CONFIG_FILE}"
else
    if [ -f ${CONFIG_FILE}.tpl ]; then
        envtpl ${CONFIG_FILE}.tpl
        if [ $? -ne 0 ]; then
            echo "ERROR - unable to generate $CONFIG_FILE"
            exit 1
        fi
    else
        echo "INFO - no ${CONFIG_FILE}.tpl found, will look for ${CONFIG_FILE}..."
    fi
fi
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR - can't find ${CONFIG_FILE}"
    exit 1
fi


if [[ -f "/data/.init_script_executed" && "x$FORCE_INIT" != "xtrue" ]]; then
    echo "=> The initialization script had been executed before, skipping ..."
else
    echo "=> Starting InfluxDB in background ..."
    influxd -config=${CONFIG_FILE} &

    wait_for_start_of_influxdb

    #Create the admin user
    if [ -n "${ADMIN_USER}" ] || [ -n "${INFLUXDB_INIT_PWD}" ]; then
        echo "=> Creating admin user"
        influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -execute="CREATE USER ${ADMIN} WITH PASSWORD '${PASS}' WITH ALL PRIVILEGES"
    fi

    # Pre create database on the initiation of the container
    if [ -n "${PRE_CREATE_DB}" ]; then
        echo "=> About to create the following database: ${PRE_CREATE_DB}"
        arr=$(echo ${PRE_CREATE_DB} | tr ";" "\n")

        for x in $arr
        do
            echo "=> Creating database: ${x}"
            echo "CREATE DATABASE ${x}" >> /tmp/init.influxql
        done
    fi

    # Execute influxql queries contained inside $CONFIG_EXTRA_DIR
    if [ -d "$CONFIG_EXTRA_DIR" ] || [ -f "/tmp/init.influxql" ]; then
        echo "=> About to execute the initialization script"

        for f in $CONFIG_EXTRA_DIR/*.influxql; do
            echo "add init script $(basename $f)"
            cat "$f" >> /tmp/init.influxql
        done

        echo "=> Executing the influxql script..."
        influx -host=${INFLUX_HOST} -port=${INFLUX_API_PORT} -username=${ADMIN} -password="${PASS}" -import -path /tmp/init.influxql

        echo "=> Influxql script executed."
        touch "/data/.init_script_executed"
        rm /tmp/init.influxql
    else
        echo "=> No initialization script need to be executed"
    fi

    echo "=> Stopping InfluxDB ..."
    if ! kill -s TERM %1 || ! wait %1; then
        echo >&2 'InfluxDB init process failed.'
        exit 1
    fi
fi

echo "=> Starting InfluxDB in foreground ..."
CMD="influxd"
CMDARGS="-config=${CONFIG_FILE}"
export AMP_LAUNCH_CMD="$CMD $CMDARGS"
if [[ -n "$CONSUL" && -n "$PILOT" ]]; then
    echo "registering in Consul with $PILOT"
    exec "$PILOT" "$CMD" $CMDARGS
else
    echo "not registering in Consul"
    exec "$CMD" $CMDARGS
fi

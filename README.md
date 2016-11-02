# docker-influxdb

[InfluxDB](https://influxdata.com/time-series-platform/influxdb/) image based on Alpine linux.

## Usage

To create the image `appcelerator/influxdb`, execute the following command in this folder:

    docker build -t appcelerator/influxdb .

You can now push new image to the registry:

    docker push appcelerator/influxdb


## Running your InfluxDB image

Start your image binding the external ports `8083` and `8086` in all interfaces to your container.

    docker run -d -p 8083:8083 -p 8086:8086 appcelerator/influxdb

Docker containers are easy to delete. If you delete your container instance and your cluster goes offline, you'll lose the InfluxDB store and configuration. If you are serious about keeping InfluxDB data persistently, then consider adding a volume mapping to the containers `/data` folder.

## Configuration (ENV, -e)

Variable | Description | Default value | Sample value 
-------- | ----------- | ------------- | ------------
FORCE_HOSTNAME | Sets the hostname of the container | localhost | auto 
ADMIN_USER | InfluxDB admin user | root | root 
INFLUXDB_INIT_PWD | InfluxDB admin password | root | mlkj3l6$ 
PRE_CREATE_DB | list of databases to create, semi colon separated | **None** | telegraf 
GRAPHITE_DB | Graphite database | | 
GRAPHITE_BINDING | Graphite binding | :2003 | 
GRAPHITE_PROTOCOL | Graphite protocol | tcp | 
GRAPHITE_TEMPLATE | Graphite template | instance.profile.measurement* | 
COLLECTD_DB | Collectd database | | 
COLLECTD_BINDING | Collectd binding | :25826 | 
COLLECTD_RETENTION_POLICY | Collectd retention policy | | 
UDP_DB | UDP listener database | | udp
UDP_PORT | UDP listener for InfluxDB line protocol data | 8089 | 
CONFIG_ARCHIVE_URL | URL of a configuration archive | | 


## Initially execute influxql script 

Use the CONFIG_ARCHIVE_URL or alternatively use a local volume mapping to a file in /etc/extra-config/influxdb/ if you want a script to be executed the first time the container starts. Each influxql command on separated line. For example:

### Docker run command

    docker run -d -p 8083:8083 -p 8086:8086 -v /tmp/init_script.influxql:/etc/extra-config/influxdb/init_script.influxql:ro appcelerator/influxdb:latest
or
    docker run -d -p 8083:8083 -p 8086:8086 -e CONFIG_ARCHIVE_URL=https://download.example.com/config/influxdb.tgz appcelerator/influxdb:latest

### The influxdb script

    ALTER  RETENTION POLICY default ON telegraf DURATION 1d SHARD DURATION 2h DEFAULT
    CREATE RETENTION POLICY warm ON telegraf DURATION 15d REPLICATION 1 SHARD DURATION 1d

Any script found in /etc/extra-config/influxdb/ will be loaded at start.

The archive should contain under a top directory one or both directory:
- base-config/influxdb
- extra-config/influxdb

## Tags

- influxdb-0.13
- influxdb-1.0, latest
- influxdb-1.1

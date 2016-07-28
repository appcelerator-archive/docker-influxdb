docker-influxdb
=====================

[![Build Status](http://drone.amp.appcelerator.io:8000/api/badges/appcelerator/docker-influxdb/status.svg)](http://drone.amp.appcelerator.io:8000/appcelerator/docker-influxdb)

InfluxDB image


Usage
-----

To create the image `appcelerator/influxdb`, execute the following command in this folder:

    docker build -t appcelerator/influxdb .

You can now push new image to the registry:

    docker push appcelerator/influxdb


Running your InfluxDB image
---------------------------

Start your image binding the external ports `8083` and `8086` in all interfaces to your container. Ports `8090` and `8099` are only used for clustering and should not be exposed to the internet:

```docker run -d -p 8083:8083 -p 8086:8086 appcelerator/influxdb```

`Docker` containers are easy to delete. If you delete your container instance and your cluster goes offline, you'll lose the InfluxDB store and configuration. If you are serious about keeping InfluxDB data persistently, then consider adding a volume mapping to the containers `/data` folder:

```docker run -d --volume=/var/influxdb:/data -p 8083:8083 -p 8086:8086 appcelerator/influxdb```

Initially create Database
-------------------------
Use `-e PRE_CREATE_DB="db1;db2;db3"` to create database named "db1", "db2", and "db3" on the first time the container starts automatically. Each database name is separated by `;`. For example:

```docker run -d -p 8083:8083 -p 8086:8086 -e ADMIN_USER="root" -e INFLUXDB_INIT_PWD="somepassword" -e PRE_CREATE_DB="db1;db2;db3" appcelerator/influxdb:latest```

Initially execute influxql script 
---------------------------------
Use `-v /tmp/init_script.influxql:/etc/extra-config/influxdb/init.influxql:ro` if you want that script to been executed on the first time the container starts automatically. Each influxql command on separated line. For example:

- Docker run command
```
docker run -d -p 8083:8083 -p 8086:8086 -e ADMIN_USER="root" -e INFLUXDB_INIT_PWD="somepassword" -v /tmp/init_script.influxql:/etc/extra-config/influxdb/init_script.influxql:ro appcelerator/influxdb:latest
```

- The influxdb script
```
CREATE DATABASE mydb
CREATE USER writer WITH PASSWORD 'writerpass'
CREATE USER reader WITH PASSWORD 'readerpass'
GRANT WRITE ON mydb TO writer
GRANT READ ON mydb TO reader
```

Any script found in /etc/extra-config/influxdb/ will be loaded at start.

An other way to load default configuration is to download a tarball archive from a public site. Use the CONFIG_ARCHIVE_URL for that:

```
docker run -d -p 8083:8083 -p 8086:8086 -e CONFIG_ARCHIVE_URL=https://download.example.com/config/influxdb.tgz appcelerator/influxdb:latest
```

The archive should contain under a top directory one or both directory:
- base-config/influxdb
- extra-config/influxdb

amp-pilot
---------------

To enable amp-pilot, specify the Consul URL, and mount the amp-pilot in /bin/amppilot/amp-pilot.alpine:

```docker run -d -p 8083:8083 -p 8086:8086 -e CONSUL=consul:8500 -v /bin/amppilot:/bin/amppilot/amp-pilot.alpine:ro appcelerator/influxdb```


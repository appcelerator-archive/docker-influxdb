FROM appcelerator/amp:latest
MAINTAINER Nicolas Degory <ndegory@axway.com>

ENV INFLUXDB_VERSION 0.13.0

RUN apk update && apk upgrade && \
    apk --virtual build-deps add go>1.6 curl git gcc musl-dev make && \
    export GOPATH=/go && \
    go get -v github.com/influxdata/influxdb && \
    cd $GOPATH/src/github.com/influxdata/influxdb && \
    git checkout -q --detach "v${INFLUXDB_VERSION}" && \
    go get -v ./... && \
    go install -v ./... && \
    chmod +x $GOPATH/bin/* && \
    mv $GOPATH/bin/* /bin/ && \
    mkdir -p /etc/influxdb /data/influxdb /data/influxdb/meta /data/influxdb/data /var/tmp/influxdb/wal /var/log/influxdb && \
    apk del build-deps && cd / && rm -rf $GOPATH/ /var/cache/apk/*

ENV ADMIN_USER root
ENV INFLUXDB_INIT_PWD root

ADD types.db /usr/share/collectd/types.db
ADD config.toml /config/config.toml.tpl
ADD run.sh /run.sh

ENV PRE_CREATE_DB **None**
ENV SSL_SUPPORT **False**
ENV SSL_CERT **None**

#ENV CONSUL=consul:8500
# ContainerPilot scripts and configuration
ENV CP_SERVICE_NAME=influxdb
ENV CP_SERVICE_PORT=8086
ENV CP_SERVICE_BIN=influxd
ENV CP_DEPENDENCIES='[{"name": "amp-log-agent", "onChange": "ignore"}]'

# Admin server WebUI
EXPOSE 8083
# HTTP API
EXPOSE 8086

VOLUME ["/data"]

CMD ["/start.sh"]

LABEL axway_image="influxdb"
# will be updated whenever there's a new commit
LABEL commit=${GIT_COMMIT}
LABEL branch=${GIT_BRANCH}

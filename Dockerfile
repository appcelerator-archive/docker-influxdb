FROM appcelerator/alpine:20160928
MAINTAINER Nicolas Degory <ndegory@axway.com>

ENV INFLUXDB_VERSION 1.1.0

RUN apk update && apk upgrade && \
    apk --virtual build-deps add go curl git gcc musl-dev make patch && \
    apk -v add curl go@community && \
    export GOPATH=/go && \
    go get -v github.com/influxdata/influxdb && \
    cd $GOPATH/src/github.com/influxdata/influxdb && \
    git checkout -q --detach "v${INFLUXDB_VERSION}" && \
    python ./build.py && \
    chmod +x ./build/influx* && \
    mv ./build/influx* /bin/ && \
    mkdir -p /etc/influxdb /data/influxdb /data/influxdb/meta /data/influxdb/data /var/tmp/influxdb/wal /var/log/influxdb && \
    apk del binutils-libs binutils gmp isl libgomp libatomic libgcc pkgconf pkgconfig mpfr3 mpc1 libstdc++ gcc go && \
    apk del build-deps && cd / && rm -rf $GOPATH/ /var/cache/apk/*

RUN apk update && apk add util-linux && rm -rf /var/cache/apk/*

ENV ADMIN_USER root
ENV INFLUXDB_INIT_PWD root

ADD types.db /usr/share/collectd/types.db
ADD config.toml /etc/influxdb/config.toml.tpl
ADD run.sh /run.sh

ENV PRE_CREATE_DB **None**

# Admin server WebUI
EXPOSE 8083
# HTTP API
EXPOSE 8086

VOLUME ["/data"]

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/run.sh"]

HEALTHCHECK --interval=5s --retries=24 --timeout=1s CMD curl -sI localhost:8086/ping | grep -q "204 No Content"

LABEL axway_image="influxdb"
# will be updated whenever there's a new commit
LABEL commit=${GIT_COMMIT}
LABEL branch=${GIT_BRANCH}

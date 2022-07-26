FROM debian

ENV LANG en_US.utf8
ENV PG_MAJOR 14
ENV PG_VERSION 14.4
ENV PGDATA /var/lib/postgresql/data

RUN echo "deb-src http://deb.debian.org/debian testing main contrib non-free" >> /etc/apt/sources.list

RUN set -ex \
  && apt-get update \
  && apt-get install -y \
      ca-certificates \
      curl \
      procps \
      sysstat \
      libldap2-dev \
      python-dev \
      libreadline-dev \
      libssl-dev \
      bison \
      flex \
      libghc-zlib-dev \
      libcrypto++-dev \
      libxml2-dev \
      libxslt1-dev \
      bzip2 \
      make \
      gcc \
      unzip \
      python \
      locales \
      libossp-uuid-dev \
      gdb \
      dpkg-dev \
      glibc-source \
  && tar xvf /usr/src/glibc/glibc-2.31.tar.xz

RUN set -ex \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 en_US.UTF-8 \
  && mkdir /u01/ && groupadd -r postgres --gid=999 \
  && useradd -m -r -g postgres --uid=999 postgres \
  && chown postgres:postgres /u01/ \
  && mkdir -p "$PGDATA" \
  && chown -R postgres:postgres "$PGDATA" \
  && chmod 700 "$PGDATA"

USER postgres
COPY . /home/postgres/src
USER root

RUN ["chown", "-R", "postgres:postgres", "/home/postgres"]

RUN set -ex \
  && cd /home/postgres/src \
  && ./configure --enable-integer-datetimes --with-uuid=ossp \
      --enable-thread-safety --with-pgport=5432 --enable-cassert --enable-debug\
      CFLAGS="-ggdb -Og -g3 -fno-omit-frame-pointer" \
  && make all \
  && make install \
  && make -C contrib install

ENV PATH="${PATH}:/usr/local/pgsql/bin/"
COPY docker-entrypoint.sh /
ENV LANG en_US.utf8
RUN ["chmod", "755", "/docker-entrypoint.sh"]
USER postgres
EXPOSE 5432
ENTRYPOINT ["/docker-entrypoint.sh"]

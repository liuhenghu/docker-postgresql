# FROM 1005663978/postgresql10.7:centos AS builder







FROM centos:7

RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
         -i.bak /etc/yum.repos.d/CentOS-Base.repo; yum install -y systemd-sysv perl python3 libxslt-devel libicu-devel wget 

COPY epel.repo  pgdg-common.repo pgdg10-archive.repo /etc/yum.repos.d/


COPY gosu docker-entrypoint.sh  /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh; chmod +x /usr/local/bin/gosu; gosu --version; gosu nobody true

ENV LANG en_US.utf8

RUN mkdir /docker-entrypoint-initdb.d

RUN yum install -y postgresql10-10.7-2PGDG.rhel7  postgresql10-server-10.7-2PGDG.rhel7 postgresql10-contrib-10.7-2PGDG.rhel7 postgresql10-plpython-10.7-2PGDG.rhel7.x86_64

ENV PATH $PATH:/usr/pgsql-10/bin

RUN sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/pgsql-10/share/postgresql.conf.sample

ENV PGDATA /var/lib/pgsql/10/data
# this 1777 will be replaced by 0700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 1777 "$PGDATA"
VOLUME /var/lib/pgsql/10/data

ADD postgis-2.5.9.tar.gz  /

RUN yum install -y gcc gcc-c++ make automake autoconf libtool readline-devel \
    wget unzip json-c-devel proj72-devel geos310-devel gdal31-devel libxml2-devel SFCGAL SFCGAL-devel postgresql10-devel-10.7 pcre-devel

RUN cd /usr && cp -r gdal31/* . && \cp -r geos310/* . && cp -r libgeotiff17/* . && cp -r ogdi41/* . && cp -r proj72/*  . && \cp -r sqlite330/* . && \
    cd / &&  cd /postgis-2.5.9  && ./configure --with-pgconfig=/usr/pgsql-10/bin/pg_config --with-sfcgal  && \
    make && make install


ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT

EXPOSE 5432

CMD ["postgres"]
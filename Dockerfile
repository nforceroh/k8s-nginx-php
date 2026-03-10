FROM ghcr.io/nforceroh/k8s-alpine-baseimage:3.23

ARG \
  BUILD_DATE=now \
  VERSION=unknown 

LABEL \
  org.label-schema.maintainer="Sylvain Martin (sylvain@nforcer.com)" \
  org.label-schema.build-date="${BUILD_DATE}" \
  org.label-schema.version="${VERSION}" \
  org.label-schema.vcs-url="https://github.com/nforcer/k8s-nginx-php" \
  org.label-schema.vcs-ref="${VERSION}" \
  org.label-schema.schema-version="1.0"

RUN \
  apk add --no-cache \
    memcached \
    nginx \
    nginx-mod-http-brotli \
    nginx-mod-http-dav-ext \
    nginx-mod-http-echo \
    nginx-mod-http-fancyindex \
    nginx-mod-http-geoip \
    nginx-mod-http-geoip2 \
    nginx-mod-http-headers-more \
    nginx-mod-http-image-filter \
    nginx-mod-http-perl \
    nginx-mod-http-redis2 \
    nginx-mod-http-set-misc \
    nginx-mod-http-upload-progress \
    nginx-mod-http-xslt-filter \
    nginx-mod-mail \
    nginx-mod-rtmp \
    nginx-mod-stream \
    nginx-mod-stream-geoip \
    nginx-mod-stream-geoip2 \
    nginx-vim \
    php85-bcmath \
    php85-bz2 \
    php85-dom \
    php85-exif \
    php85-ftp \
    php85-fpm \
    php85-gd \
    php85-gmp \
    php85-imap \
    php85-intl \
    php85-ldap \
    php85-mysqli \
    php85-mysqlnd \
    php85-pdo_mysql \
    php85-pdo_odbc \
    php85-pdo_pgsql \
    php85-pdo_sqlite \
    php85-pear \
    php85-pecl-apcu \
    php85-pecl-memcached \
    php85-pecl-redis \
    php85-pgsql \
    php85-phar \
    php85-posix \
    php85-soap \
    php85-sockets \
    php85-sodium \
    php85-sqlite3 \
    php85-tokenizer \
    php85-xmlreader \
    php85-xsl

RUN \
  echo "**** configure nginx ****" \
  && rm -f /etc/nginx/conf.d/stream.conf \
  && rm -f /etc/nginx/http.d/default.conf \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && adduser -u 82 -D -S -G www-data www-data \
  && mkdir -p /data/web \
  && echo "**** guarantee correct php version is symlinked ****"  \
  && if [ "$(readlink /usr/bin/php)" != "php85" ]; then \
    rm -rf /usr/bin/php  && \
    ln -s /usr/bin/php85 /usr/bin/php; \
  fi 

RUN \
  echo "**** add run paths to php runtime config ****" \
  && grep -qxF 'include=/config/php/*.conf' /etc/php85/php-fpm.conf || echo 'include=/config/php/*.conf' >> /etc/php85/php-fpm.conf  \
  && echo "**** install php composer ****" && \
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')" && \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")" && \
  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
    >&2 echo 'ERROR: Invalid installer checksum' && \
    rm composer-setup.php && \
    exit 1; \
  fi && \
  php composer-setup.php --install-dir=/usr/bin && \
  rm composer-setup.php

ADD /content /
ADD --chmod=755 /content/etc/s6-overlay /etc/s6-overlay


# ports and volumes
EXPOSE 8080

VOLUME /config

#ENTRYPOINT [ "/init" ]
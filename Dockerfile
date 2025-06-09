FROM ghcr.io/nforceroh/k8s-alpine-baseimage:latest

ARG \
  BUILD_DATE=now \
  VERSION=unknown

LABEL \
  maintainer="Sylvain Martin (sylvain@nforcer.com)"

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
    php83-bcmath \
    php83-bz2 \
    php83-dom \
    php83-exif \
    php83-ftp \
    php83-gd \
    php83-gmp \
    php83-imap \
    php83-intl \
    php83-ldap \
    php83-mysqli \
    php83-mysqlnd \
    php83-opcache \
    php83-pdo_mysql \
    php83-pdo_odbc \
    php83-pdo_pgsql \
    php83-pdo_sqlite \
    php83-pear \
    php83-pecl-apcu \
    php83-pecl-mcrypt \
    php83-pecl-memcached \
    php83-pecl-redis \
    php83-pgsql \
    php83-phar \
    php83-posix \
    php83-soap \
    php83-sockets \
    php83-sodium \
    php83-sqlite3 \
    php83-tokenizer \
    php83-xmlreader \
    php83-xsl

RUN \
  echo "**** configure nginx ****" \
  && echo 'fastcgi_param  HTTP_PROXY         ""; # https://httpoxy.org/' >> \
    /etc/nginx/fastcgi_params \
  && echo 'fastcgi_param  PATH_INFO          $fastcgi_path_info; # http://nginx.org/en/docs/http/ngx_http_fastcgi_module.html#fastcgi_split_path_info' >> \
    /etc/nginx/fastcgi_params \
  && echo 'fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name; # https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/#connecting-nginx-to-php-fpm' >> \
    /etc/nginx/fastcgi_params \
  && echo 'fastcgi_param  SERVER_NAME        $host; # Send HTTP_HOST as SERVER_NAME. If HTTP_HOST is blank, send the value of server_name from nginx (default is `_`)' >> \
    /etc/nginx/fastcgi_params \
  && rm -f /etc/nginx/conf.d/stream.conf \
  && rm -f /etc/nginx/http.d/default.conf \
  && echo "**** guarantee correct php version is symlinked ****"  \
  && if [ "$(readlink /usr/bin/php)" != "php84" ]; then \
    rm -rf /usr/bin/php  && \
    ln -s /usr/bin/php83 /usr/bin/php; \
  fi 

RUN \
  echo "**** configure php ****"  \
  && sed -i "s#;error_log = log/php83/error.log.*#error_log = /config/log/php/error.log#g" \
    /etc/php83/php-fpm.conf  \
  && sed -i "s#user = nobody.*#user = abc#g" \
    /etc/php83/php-fpm.d/www.conf  \
  && sed -i "s#group = nobody.*#group = abc#g" \
    /etc/php83/php-fpm.d/www.conf  \
  && echo "**** add run paths to php runtime config ****" \
  && grep -qxF 'include=/config/php/*.conf' /etc/php83/php-fpm.conf || echo 'include=/config/php/*.conf' >> /etc/php83/php-fpm.conf  \
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
EXPOSE 80 443

VOLUME /config

#ENTRYPOINT [ "/init" ]
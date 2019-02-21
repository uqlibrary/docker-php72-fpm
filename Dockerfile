FROM uqlibrary/alpine:3.9

ENV COMPOSER_VERSION=1.8.4
ENV XDEBUG_VERSION=2.7.0RC2
ENV IGBINARY_VERSION=2.0.8
ENV NEWRELIC_VERSION=8.3.0.226
ENV PHP_MEMCACHED_VERSION=3.1.3
ENV NR_INSTALL_SILENT=1
ENV NR_INSTALL_PHPLIST=/usr/bin
ENV BUILD_DEPS file re2c autoconf make g++ gcc groff less php7-dev libmemcached-dev cyrus-sasl-dev zlib-dev musl pcre-dev

COPY ./fs/docker-entrypoint.sh /usr/sbin/docker-entrypoint.sh

RUN apk upgrade --update --no-cache && \
    apk add --update --no-cache \
    ca-certificates \
    curl \
    bash \
    git sqlite mysql-client libmemcached

RUN apk add --update --no-cache \
        php7-session php7-mcrypt php7-soap php7-openssl php7-gmp php7-pdo_odbc php7-json php7-dom php7-pdo php7-zip \
        php7-mysqli php7-sqlite3 php7-pdo_pgsql php7-bcmath php7-gd php7-odbc php7-pdo_mysql php7-pdo_sqlite \
        php7-gettext php7-xmlreader php7-xmlwriter php7-xmlrpc php7-xml php7-simplexml php7-bz2 php7-iconv \
        php7-pdo_dblib php7-curl php7-ctype php7-pcntl php7-posix php7-phar php7-opcache php7-mbstring php7-zlib \
        php7-fileinfo php7-tokenizer php7-sockets php7-phar php7-intl php7-pear php7-ldap php7-phpdbg php7-fpm php7 \
    #
    # Build deps
    && apk add --no-cache --virtual .build-deps $BUILD_DEPS \
    #
    # XDebug
    && cd /tmp && wget -q https://xdebug.org/files/xdebug-${XDEBUG_VERSION}.tgz \
    && tar -zxvf xdebug-${XDEBUG_VERSION}.tgz \
    && cd xdebug-${XDEBUG_VERSION} && phpize \
    && ./configure --enable-xdebug && make && make install \
    #
    # igbinary
    && cd /tmp && wget -q https://github.com/igbinary/igbinary/releases/download/${IGBINARY_VERSION}/igbinary-${IGBINARY_VERSION}.tgz \
    && tar -zxvf igbinary-${IGBINARY_VERSION}.tgz \
    && cd igbinary-${IGBINARY_VERSION} && phpize \
    && ./configure CFLAGS="-O2 -g" --enable-igbinary && make && make install \
    && echo 'extension=igbinary.so' >> /etc/php7/conf.d/igbinary.ini \
    # memcache
    && cd /tmp && wget -q https://github.com/php-memcached-dev/php-memcached/archive/v${PHP_MEMCACHED_VERSION}.tar.gz \
    && tar -zxvf v${PHP_MEMCACHED_VERSION}.tar.gz \
    && cd php-memcached-${PHP_MEMCACHED_VERSION} && phpize \
    && ./configure --disable-memcached-sasl --enable-memcached-igbinary && make && make install \
    && echo 'extension=memcached.so' >> /etc/php7/conf.d/memcached.ini \
    && cd \
    && rm -rf /tmp/* \
    #
    # Composer
    && curl -sS https://getcomposer.org/installer | php7 -- --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
    && composer global require "hirak/prestissimo:0.3.8" \
    #
    # NewRelic (disabled by default)
    && mkdir -p /opt && cd /opt \
    && wget -q https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    && tar -zxf newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    && rm -f newrelic-php5-${NEWRELIC_VERSION}-linux-musl.tar.gz \
    && ./newrelic-php5-${NEWRELIC_VERSION}-linux-musl/newrelic-install install \
    && mv /etc/php7/conf.d/newrelic.ini /etc/newrelic.ini \
    #
    # Remove build deps
    && rm -rf /var/cache/apk/* \
    && apk del --purge .build-deps \
    #
    # Make scripts executable
    && chmod +x /usr/sbin/docker-entrypoint.sh

ADD fs /

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9000

WORKDIR /app

#!/bin/bash
set -e

: ${POSTGRES_PORT_5432_TCP_ADDR:?"--link to a PostgreSQL container is not set"}
: ${SELF_URL_PATH:?"-e SELF_URL_PATH is not set"}

sed -ri 's#SELF_URL_PATH#'"${SELF_URL_PATH}"'#;' /etc/nginx/sites-available/default

sed -ri 's/;opcache.enable=0/opcache.enable=1/;' /etc/php5/fpm/php.ini
sed -ri 's/;opcache.enable_cli=0/opcache.enable_cli=1/;' /etc/php5/fpm/php.ini
sed -ri 's/;opcache.memory_consumption=64/opcache.memory_consumption=128/;' /etc/php5/fpm/php.ini
sed -ri 's/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/;' /etc/php5/fpm/php.ini
sed -ri 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/;' /etc/php5/fpm/php.ini

echo "env[POSTGRES_PORT_5432_TCP_ADDR] = \$POSTGRES_PORT_5432_TCP_ADDR" >> /etc/php5/fpm/pool.d/www.conf

sed -ri 's/"localhost"/getenv("POSTGRES_PORT_5432_TCP_ADDR")/;' config.php
sed -ri 's/"fox"/"tt_rss"/;' config.php
sed -ri 's/"XXXXXX"/""/;' config.php

sed -ri 's#http://example\.org/tt-rss/#'"${SELF_URL_PATH}"'#;' config.php

if psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -U postgres -lqt | cut -d \| -f 1 | grep tt_rss; then
	echo 'database `tt_rss` found; skipping schema installation'

else
	echo 'database `tt_rss` not found; running schema installation'

	createuser -h "$POSTGRES_PORT_5432_TCP_ADDR" -U postgres --no-superuser --no-createrole --no-createdb tt_rss
	createdb -h "$POSTGRES_PORT_5432_TCP_ADDR" -U postgres -O tt_rss tt_rss
	psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -U tt_rss -d tt_rss -a -f schema/ttrss_schema_pgsql.sql

fi

echo '===='

exec "$@"

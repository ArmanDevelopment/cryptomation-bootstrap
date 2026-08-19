# Build context: cryptomation-monolith/ (sibling Laravel project)
# This Dockerfile is invoked from cryptomation-bootstrap, not from the source.
#
# At runtime docker compose:
#   1. Bind-mounts cryptomation-monolith/ → /var/www/html
#   2. Mounts named volume vendor → /var/www/html/vendor
#
# composer install runs in before-start.sh (same hash-stamp pattern as frontend npm).

# PHP 8.4: composer.lock resolved Symfony 8 (requires >=8.4.1).
# composer.json still allows ^8.3, but install from this lockfile needs 8.4.
FROM php:8.4-fpm-bookworm

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN install-php-extensions pdo_pgsql pgsql mbstring bcmath intl zip opcache pcntl \
 && apt-get update \
 && apt-get install -y --no-install-recommends git unzip \
 && rm -rf /var/lib/apt/lists/* \
 && usermod -o -u 1000 www-data \
 && groupmod -o -g 1000 www-data \
 && printf '%s\n' '[www]' 'clear_env = no' > /usr/local/etc/php-fpm.d/zz-clear-env.conf \
 && git config --global --add safe.directory /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

CMD ["php-fpm"]

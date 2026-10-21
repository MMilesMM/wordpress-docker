# WordPress (Apache) with a few extra PHP extensions and Apache modules.
# Pin the base so builds are reproducible; bump deliberately.
ARG WORDPRESS_TAG=7.1-php8.5-apache
FROM wordpress:${WORDPRESS_TAG}

# Builds the extensions and removes their build dependencies afterwards,
# so no -dev packages end up in the final image.
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/

RUN a2enmod headers ext_filter \
    && install-php-extensions tidy soap redis brotli \
    && rm -rf /tmp/* /var/lib/apt/lists/*

LABEL org.opencontainers.image.title="wordpress-apache-php-fix" \
      org.opencontainers.image.description="WordPress Apache image with tidy, soap, redis and brotli" \
      org.opencontainers.image.licenses="GPL-3.0"

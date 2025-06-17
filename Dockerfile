FROM wordpress:latest

# Aktivieren von Apache-Modulen
RUN a2enmod headers ext_filter

# Systempakete aktualisieren und installieren
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y libtidy-dev redis-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# PHP-Module installieren und aktivieren
RUN docker-php-ext-install tidy && \
    docker-php-ext-enable tidy

# Redis-Installation optimieren
RUN pecl list | grep -q "^redis" || pecl install redis && \
    docker-php-ext-enable redis

# Brotli-Installation optimieren
RUN pecl list | grep -q "^brotli" || pecl install brotli && \
    docker-php-ext-enable brotli

# PHP SOAP installieren und aktivieren
RUN apt-get update && \
    apt-get install -y libxml2-dev
RUN docker-php-ext-install soap && \
    docker-php-ext-enable soap

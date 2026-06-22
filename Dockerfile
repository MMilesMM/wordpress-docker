FROM wordpress:latest

RUN a2enmod headers ext_filter

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y libtidy-dev libxml2-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install tidy soap && \
    docker-php-ext-enable tidy soap

RUN pecl install redis && \
    docker-php-ext-enable redis

RUN pecl install brotli && \
    docker-php-ext-enable brotli

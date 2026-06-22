# Custom Wordpress Docker Compose

## Why?
I needed a docker image which has a couple more php modules enabled than the https://hub.docker.com/_/wordpress Image
## How to use? 
You can use this `docker-compose.yml` file and edit it to your liking
Dont forget the .env file!

```YAML
services:
  db:
    image: mariadb:12.1
    restart: unless-stopped
    environment:
      TZ: Europe/Berlin
      MARIADB_ROOT_PASSWORD: $MARIADB_ROOT_PASSWORD
      MYSQL_USER: $MYSQL_USER
      MYSQL_PASSWORD: $MYSQL_PASSWORD
      MYSQL_DATABASE: wordpress
      MARIADB_AUTO_UPGRADE: 1
    volumes:
      - ./db:/var/lib/mysql
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - ./redis:/data
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  wordpress:
    depends_on:
      - db
      - redis
    build: .
    image: mmilesmm/wordpress-apache-php-fix:latest
    restart: unless-stopped
    env_file: .env
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=$MYSQL_USER
      - WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - ./wordpress_data:/var/www/html
      - ./wordpress.ini:/usr/local/etc/php/conf.d/wordpress.ini
    ports:
      - "127.0.0.1:${WEB_PORT:-3000}:80"
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

Basic `.env` file:

```
MARIADB_ROOT_PASSWORD=securepasswordwhichshouldnotbetherootpassword
MYSQL_USER=wordpress
MYSQL_PASSWORD=supersecretandlongpasswordyoushouldchange
WEB_PORT=[port]
```

Also, please adjust the `wordpress.ini` to your liking as well, this is my default (I know these values are not optimal but it works and I can´t be bothered but if you have suggestions feel free to open an issue):

```ini
file_uploads = On

memory_limit = 512M

upload_max_filesize = 2048M
post_max_size = 3096M

max_execution_time = 300
max_input_time = 1000

max_input_vars = 5000

opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 60
```

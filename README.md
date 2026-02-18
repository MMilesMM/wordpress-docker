# Custom Wordpress Docker Compose

## Wyh?
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
  wordpress:
    depends_on:
      - db
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
```

Basic `.env` file:

```
MARIADB_ROOT_PASSWORD=securepasswordwhichshouldnotbetherootpassword
MYSQL_USER=wordpress
MYSQL_PASSWORD=supersecretandlongpasswordyoushouldchange
WEB_PORT=[port]
```

Also, please adjust the `wordpress.ini` to your liking as well, this is my default (I know they are not optimal but it works and I can´t be bothered but if you have suggestions feel free to open an issue):

```ini
file_uploads = On
memory_limit = 256M
upload_max_filesize = 2048M
post_max_size = 3096M
max_execution_time = 300
max_input_time = 1000
```

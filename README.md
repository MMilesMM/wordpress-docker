# WordPress Docker (single site)

> **Where this repository lives:** the main repository is on my own Forgejo at
> [git.mqit.de/mmilesmm/wordpress-docker](https://git.mqit.de/mmilesmm/wordpress-docker).
> Development, CI and the Docker Hub builds happen there, and every change is mirrored
> automatically to [GitHub](https://github.com/MMilesMM/wordpress-docker), so you will
> always find the complete code on both. The GitHub copy is overwritten by the mirror,
> so changes are not merged there directly: issues and pull requests on GitHub are
> welcome, and I apply accepted changes in the main repository.

A WordPress image with a few more PHP modules than the [official image](https://hub.docker.com/_/wordpress), plus a ready-to-use Docker Compose setup for **one** WordPress site with its own MariaDB and Redis.

Image: [`mmilesmm/wordpress-apache-php-fix`](https://hub.docker.com/r/mmilesmm/wordpress-apache-php-fix)

## What's in the image

Based on the pinned official `wordpress:7.1-php8.5-apache`, plus:

- Apache modules: `headers`, `ext_filter`
- PHP extensions: `tidy`, `soap`, `redis`, `brotli`

## Quick start

```bash
mkdir wordpress && cd wordpress
for f in docker-compose.yml wordpress.ini env.example; do
  curl -fsSLO https://raw.githubusercontent.com/MMilesMM/wordpress-docker/main/$f
done

cp env.example .env
# fill in the passwords, e.g. with: openssl rand -hex 24
nano .env

docker compose up -d
```

WordPress listens on `127.0.0.1:${WEB_PORT}` (default 3000, see [Reverse proxy on another server](#reverse-proxy-on-another-server)). Put a reverse proxy with TLS in front of it, e.g. Caddy:

```caddy
example.com {
    encode zstd gzip
    reverse_proxy 127.0.0.1:3000
}
```

HTTPS (`X-Forwarded-Proto`) and the client IP (`X-Forwarded-For`) from the proxy are detected automatically.

## `.env`

| Variable | Required | Purpose |
| --- | --- | --- |
| `MARIADB_ROOT_PASSWORD` | yes | MariaDB root password (stays in the `db` container) |
| `MYSQL_USER` / `MYSQL_PASSWORD` | yes | database user for WordPress |
| `REDIS_PASSWORD` | yes | Redis password, also passed to WordPress |
| `WEB_PORT` | no (3000) | localhost port |
| `WORDPRESS_IMAGE` | no | defaults to `mmilesmm/wordpress-apache-php-fix:5.4.0` |
| `MARIADB_VERSION` / `REDIS_VERSION` | no | default `12.3` / `7.4-alpine` |
| `REDIS_MAXMEMORY` | no (128mb) | Redis memory limit |
| `TZ` | no | default `Europe/Berlin` |
| `BIND_ADDRESS` | no (127.0.0.1) | address the WordPress port is published on |
| `WP_TRUSTED_PROXIES` | no (private networks) | space-separated proxy IPs/CIDRs allowed to set `X-Forwarded-*`; set it if `BIND_ADDRESS` is not 127.0.0.1 |
| `WP_AUTO_UPDATE_EXTENSIONS` | no (false) | `true` = automatic updates for all plugins and themes |
| `DOCKER_MTU` | no (1500) | MTU of the Docker network, see below |

## Redis object cache

Redis is ready to use. Install and enable the [Redis Object Cache](https://wordpress.org/plugins/redis-cache/) plugin in WordPress, the connection settings (`WP_REDIS_HOST`, `WP_REDIS_PASSWORD`) are already defined. Redis runs as a pure cache: password protected, limited memory with LRU eviction, no persistence.

## PHP settings

`wordpress.ini` is mounted read-only into the container. Defaults: 512M memory, 2048M uploads, 300 s execution time, opcache enabled. Adjust it and run `docker compose restart wordpress`.

## Reverse proxy on another server

By default the WordPress port is bound to `127.0.0.1`, so only a proxy on the same host can reach it. If the proxy (e.g. Nginx Proxy Manager) runs on another server, set in `.env`:

```
BIND_ADDRESS=10.0.0.10          # private IP of this host (avoid 0.0.0.0 on a public interface)
WP_TRUSTED_PROXIES=10.0.0.5     # IP(s)/CIDRs of the proxy, space-separated
```

`WP_TRUSTED_PROXIES` matters. The official WordPress image trusts `X-Forwarded-For`/`-Proto` from all private networks (10/8, 172.16/12, 192.168/16). Once the port is reachable from the LAN, anyone there could fake HTTPS or the client IP. With the list set, Apache (`mod_remoteip`) accepts the headers only from those addresses; for everyone else HTTPS and the client IP are taken from the real connection. Also restrict the port with a firewall to the proxy.

The address to enter is the one the proxy connects *from*, as seen by this host (NAT can change it). Check it with `docker compose logs --tail 20 wordpress` after setting `WP_TRUSTED_PROXIES` to something unrelated: the first column then shows the proxy's address.

Apply with `docker compose up -d`.

## Slow admin / timeouts to external servers (MTU)

If the host's network MTU is smaller than 1500 (common on OpenStack clouds: 1450), large packets from the containers get dropped. TCP connects, but the TLS handshake hangs, so WordPress runs into `cURL error 28: Connection timed out` for update checks and license servers, and the admin becomes very slow. The frontend stays fast, especially with a page cache.

Check the host MTU with `ip link`. If it is below 1500, set it in `.env` and recreate the network:

```bash
echo DOCKER_MTU=1450 >> .env
docker compose down && docker compose up -d
```

## Security

- The MariaDB root password is only given to the `db` container, not to WordPress, and root can only log in from inside that container.
- MariaDB and Redis are not published on the host; WordPress is bound to `127.0.0.1` unless `BIND_ADDRESS` says otherwise.
- `DISALLOW_FILE_EDIT` disables the theme/plugin editor in the dashboard.
- `.env`, `db/`, `redis/` and `wordpress_data/` are ignored by Git.

## Backup

```bash
docker compose exec -T db sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --databases wordpress' | gzip > wordpress-$(date +%F).sql.gz
tar -czf wordpress_data-$(date +%F).tar.gz wordpress_data
```

## Upgrading from an older version of this compose file

- Add `REDIS_PASSWORD` to your `.env` (it is now required).
- The WordPress container no longer reads the whole `.env`; only the variables above are used.
- MariaDB moves from 12.1 to 12.3 LTS automatically (`MARIADB_AUTO_UPGRADE`).
- `MARIADB_ROOT_HOST=localhost` only applies to new databases. To remove network access for root on an existing one:
  ```bash
  docker compose exec db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP USER IF EXISTS root@\"%\""'
  ```
  (check first that `root@localhost` exists: `SELECT User,Host FROM mysql.user;`)
- The image is pinned to a version tag instead of `latest`.

## Building the image yourself

```bash
docker build -t mmilesmm/wordpress-apache-php-fix:dev .
# other base: --build-arg WORDPRESS_TAG=7.1-php8.4-apache
```

## CI

The image is built on the Forgejo runner of the main repository (see above) with kaniko and pushed to Docker Hub. The workflows are in `.forgejo/workflows/`; `.github/workflows/` only runs a test build on GitHub.

| Trigger | Tags |
| --- | --- |
| push to `main` changing the Dockerfile, weekly (Mon 04:23), manual | `latest`, `sha-<short>` |
| git tag `v5.4.0` | `5.4.0`, `5.4`, `latest` |

## License

GPL-3.0

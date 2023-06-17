# Deploy instructions

`docker-compose -p reverse-proxy up -d --force-recreate

* see HugoKlepsch/reverse-proxy-network for files to create network.

* Use (create-systemd-service.sh)[create-systemd-service.sh] to create a
    systemd service that auto-starts on boot.

# Adding a new app

## Port

If your app uses a new port, add it to the list of exposed ports in
(docker-compose.yaml)[docker-compose.yaml].
If your sever has a firewall, add the port to the allowed list.

## Layer 7 (HTTP) reverse proxy

If your app should be accessed via HTTP, use this section.

* Add a new file under `config/conf.d/sites-available/`
    (link)[config/conf.d/sites-available/]
* The port in the `server` block is the port that will listen for new
    connections.
* The host and port in the `upstream` block is where the reverse proxy will
    forward new connections to.
* Add a `upstream` block that points to your app. Ex:

```
# `foo` is the name of this upstream, which we will use later
upstream foo {
    server          10.8.0.22:8929;
}
```

* Add a `server` block that listens on port 80 and redirects to HTTPS. Ex:

```
server {
    listen          80;
    server_name     foo.example.org;

    include common.conf;

    include common_https_redirect.conf;
}
```

* Add a `server` block that listens on port 443 with ssl. It should have a
    `proxy\_pass` directive that points to the upstream app (`foo` from
    earlier). Ex:

```
server {
    listen          443 ssl;
    server_name     foo.example.org;

    include common.conf;

    include ssl.conf;

    location / {
        proxy_pass http://foo;
        include common_location.conf;
    }
}
```

* In this example, TLS is terminated at the reverse-proxy and the app is
    accessed via HTTP. You should trust the connection between the
    reverse-proxy and the app, or use some other form of encryption for the
    connection. In my case the connection from reverse-proxy and app is
    tunnelled over a VPN.
* Add the configuration to the `config/conf.d/sites-enabled/`
    (directory)[config/conf.d/sites-enabled/] by making a symbolic link:

```bash
$ cd config/conf.d/sites-enabled/
$ ln -s ../sites-availble/my-site.conf my-site.conf
```

* Once you (reload configuratoin)[#reload-configuration], the new proxy will
    be availble.

## Layer 4 (TCP) reverse proxy

If your app does not use HTTP, or if it only uses TCP, use this section.

* Add a new file under `config/conf.d/stream/sites-available/`
    (link)[config/conf.d/stream/sites-available/]
* The port in the `server` block is the port that will listen for new connections.
* The host and port in the `upstream` block is where the reverse proxy will forward
    new connections to.
* Add a `upstream` block that points to your app. Ex:

```
# `foo` is the name of this upstream, which we will use later
upstream foo {
    server          10.8.0.22:8929;
}
```

* Add a `server` block that listens on a port . It should have a
    `proxy\_pass` directive that points to the upstream app (`foo` from
    earlier). Ex:

```
server {
    listen 2224;
    proxy_pass foo;
}
```

* Add the configuration to the `config/conf.d/stream/sites-enabled/`
    (directory)[config/conf.d/stream/sites-enabled/] by making a symbolic link:

```bash
$ cd config/conf.d/stream/sites-enabled/
$ ln -s ../sites-availble/my-site.conf my-site.conf
```

* Once you (reload configuratoin)[#reload-configuration], the new proxy will be availble.

# Reload configuration

You can reload configuration without restarting the server:

```bash
$ docker-compose exec reverse nginx -s reload
```

Or just restart the server:

```bash
$ docker-compose up --force-recreate -d reverse
```

OR

```bash
sudo systemctl restart reverse.service
```

# SSL

SSL was provided by [Let's Encrypt.][1]

* Fill out your `base\_domain` and `subdomains` in (init-letsencrypt.sh)[init-letsencrypt.sh].
* Set `staging` to `1` if you want to test out your config settings before making
    requests to Let's Encrypt that will count against your
    (rate limit)[https://letsencrypt.org/docs/rate-limits/].
* Run `./init-letsencrypt.sh` to initialize the Let's Encrypt configuration.
* You can then start up using `docker-compose` like normal for any subsequent boot.


Tutorials used for setting up Let's Encrypt:

* https://github.com/wmnnd/nginx-certbot/blob/master/data/nginx/app.conf
* https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71

[1]: https://letsencrypt.org/

#!/usr/bin/env bash

DOMAIN=example.com
EMAIL=info@example.com

mkdir -p letsencrypt

docker run -it --rm -v $(pwd)/letsencrypt:/letsencrypt --user $(id -u):$(id -g) certbot/certbot certonly \
    --config-dir /letsencrypt/config \
    --work-dir /letsencrypt/work \
    --logs-dir /letsencrypt/logs \
    --manual \
    --preferred-challenges=dns \
    --email $EMAIL \
    --agree-tos \
    -d $DOMAIN \
    -d *.$DOMAIN \
    -d *.gitlab.$DOMAIN \
    -d *.gitpod.$DOMAIN \
    -d *.ws.gitpod.$DOMAIN


mkdir -p sync/gitpod-self-hosted/secrets/https-certificates
find letsencrypt/config/live -name "*.pem" -exec cp {} sync/gitpod-self-hosted/secrets/https-certificates \;

openssl dhparam -out sync/gitpod-self-hosted/secrets/https-certificates/dhparams.pem 2048

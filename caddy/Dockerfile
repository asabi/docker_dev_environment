FROM caddy:2.4.6-builder-alpine AS builder

RUN xcaddy build \
#    --with github.com/caddy-dns/route53 \
    --with github.com/greenpau/caddy-security@v1.0.18

FROM caddy:2.4.6-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
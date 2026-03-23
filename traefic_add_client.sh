#!/usr/bin/env bash
set -euo pipefail

DYNAMIC_DIR="${TRAEFIK_DYNAMIC_DIR:-/etc/traefik/dynamic}"

usage() {
    echo "Usage: $0 <base-domain> <backend-ip>"
    echo "  Example: $0 cargo101.eu 10.0.1.50"
    exit 1
}

[[ $# -ne 2 ]] && usage

DOMAIN="$1"
BACKEND_IP="$2"
SLUG="${DOMAIN//./-}"
OUTFILE="${DYNAMIC_DIR}/${SLUG}.yml"

if [[ -f "$OUTFILE" ]]; then
    echo "Error: ${OUTFILE} already exists. Remove it first to recreate." >&2
    exit 1
fi

cat > "$OUTFILE" <<EOFYML
http:
  routers:
    opencloud-${SLUG}:
      rule: "Host(\`cloud.${DOMAIN}\`)"
      entryPoints: ["https"]
      service: opencloud-${SLUG}
      tls:
        certResolver: letsencrypt

    wopi-${SLUG}:
      rule: "Host(\`wopiserver.${DOMAIN}\`)"
      entryPoints: ["https"]
      service: wopi-${SLUG}
      tls:
        certResolver: letsencrypt

    collabora-${SLUG}:
      rule: "Host(\`collabora.${DOMAIN}\`)"
      entryPoints: ["https"]
      service: collabora-${SLUG}
      tls:
        certResolver: letsencrypt

  services:
    opencloud-${SLUG}:
      loadBalancer:
        servers:
          - url: "http://${BACKEND_IP}:9200"

    wopi-${SLUG}:
      loadBalancer:
        servers:
          - url: "http://${BACKEND_IP}:9300"

    collabora-${SLUG}:
      loadBalancer:
        servers:
          - url: "http://${BACKEND_IP}:9980"
EOFYML

echo "Created ${OUTFILE}"
echo "  cloud.${DOMAIN}        -> ${BACKEND_IP}:9200"
echo "  wopiserver.${DOMAIN}   -> ${BACKEND_IP}:9300"
echo "  collabora.${DOMAIN}    -> ${BACKEND_IP}:9980"
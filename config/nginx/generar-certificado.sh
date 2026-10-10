#!/usr/bin/env bash
# Genera un certificado autofirmado para la tienda (valido 365 dias).
# Uso: config/nginx/generar-certificado.sh [dias]
set -euo pipefail

dias="${1:-365}"
dir="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$dir"

openssl req -x509 -nodes -newkey rsa:2048 \
  -days "$dias" \
  -keyout "$dir/tienda.key" \
  -out "$dir/tienda.crt" \
  -subj "/C=PE/L=Lima/O=AndesMarket S.A.C./CN=tienda.andesmarket.local" \
  -addext "subjectAltName=DNS:tienda.andesmarket.local,DNS:localhost" 2>/dev/null

chmod 644 "$dir/tienda.crt"
chmod 640 "$dir/tienda.key"
echo "Certificado creado en $dir (vence en $dias dias):"
openssl x509 -in "$dir/tienda.crt" -noout -enddate

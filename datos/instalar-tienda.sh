#!/usr/bin/env bash
# Instala WordPress y WooCommerce y crea productos de ejemplo de AndesMarket.
# Se ejecuta una sola vez, con la fase 1 en marcha:  datos/instalar-tienda.sh
set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source .env
wp() { ./lab.sh wp "$@"; }

if wp core is-installed 2>/dev/null; then
  echo "La tienda ya estaba instalada. No se cambia nada."
  exit 0
fi

echo "Instalando WordPress..."
wp core install \
  --url="$TIENDA_URL" \
  --title="AndesMarket" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASSWORD" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --skip-email
wp language core install es_PE --activate || true
wp option update timezone_string "America/Lima"
wp rewrite structure '/%postname%/'

echo "Instalando WooCommerce..."
wp plugin install woocommerce --activate
wp option update woocommerce_currency PEN
wp option update woocommerce_default_country PE:LIM

echo "Creando productos de ejemplo..."
while IFS=';' read -r nombre precio stock; do
  wp wc product create --user="$WP_ADMIN_USER" \
    --name="$nombre" --type=simple --regular_price="$precio" \
    --manage_stock=true --stock_quantity="$stock" --porcelain >/dev/null
  echo "  + $nombre"
done <<'PRODUCTOS'
Licuadora Andina 600W;189.90;40
Olla arrocera 1.8L;129.00;55
Hervidor electrico 1.7L;79.90;80
Audifonos inalambricos Qhapaq;149.00;120
Mouse inalambrico;45.50;200
Teclado mecanico TKL;259.00;35
Lampara LED de escritorio;69.90;90
Juego de sartenes x3;219.00;25
PRODUCTOS

echo
echo "Tienda lista en $TIENDA_URL"
echo "Panel: $TIENDA_URL/wp-admin  (usuario: $WP_ADMIN_USER, clave en .env)"

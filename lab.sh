#!/usr/bin/env bash
# Control del laboratorio de AndesMarket S.A.C.
#
#   ./lab.sh iniciar [fase]   Levanta la empresa hasta la fase indicada (por defecto 1)
#   ./lab.sh detener          Apaga todos los contenedores (los datos se conservan)
#   ./lab.sh estado           Muestra contenedores, salud y uso de memoria
#   ./lab.sh logs <servidor>  Sigue los logs de un servidor (ej. lim-web-01)
#   ./lab.sh wp <comando>     Ejecuta wp-cli sobre la tienda (ej. ./lab.sh wp plugin list)
#   ./lab.sh destruir         Borra contenedores Y datos (pide confirmacion)
set -euo pipefail

cd "$(dirname "$0")"
FASE_MAX=1

archivos_compose() {
  local fase="$1" args=()
  for n in $(seq 1 "$fase"); do
    [[ -f "compose/fase$n.yml" ]] && args+=(-f "compose/fase$n.yml")
  done
  echo "${args[@]}"
}

compose() {
  # shellcheck disable=SC2046
  docker compose --progress quiet --env-file .env $(archivos_compose "$FASE_MAX") "$@"
}

preparar_env() {
  if [[ ! -f .env ]]; then
    echo "Creando .env con contrasenas aleatorias..."
    touch .env
    chmod 600 .env
  fi
  # Agrega a .env las variables nuevas de .env.example, con claves aleatorias
  while IFS='=' read -r var valor; do
    [[ -z "$var" || "$var" == \#* ]] && continue
    grep -q "^$var=" .env && continue
    case "$var" in
      SAMBA_*_PASSWORD) valor="Andes-$(openssl rand -hex 6)-9x!" ;;
      *_PASSWORD)       valor="$(openssl rand -hex 16)" ;;
    esac
    echo "$var=$valor" >> .env
    echo "  + $var agregada a .env"
  done < .env.example
}

preparar_certificado() {
  if [[ ! -f config/nginx/certs/tienda.crt ]]; then
    config/nginx/generar-certificado.sh
  fi
}

case "${1:-ayuda}" in
  iniciar)
    fase="${2:-1}"
    if (( fase < 1 || fase > FASE_MAX )); then
      echo "Fase $fase no disponible todavia (disponibles: 1 a $FASE_MAX)." >&2
      exit 1
    fi
    preparar_env
    preparar_certificado
    # shellcheck disable=SC2046
    docker compose --env-file .env $(archivos_compose "$fase") up -d --wait
    echo
    echo "AndesMarket fase $fase en marcha. Tienda: https://localhost:8443"
    ;;
  detener)
    compose down
    ;;
  estado)
    compose ps
    echo
    # shellcheck disable=SC2046
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}" \
      $(compose ps -q) 2>/dev/null || true
    ;;
  logs)
    [[ -n "${2:-}" ]] || { echo "Uso: ./lab.sh logs <servidor>" >&2; exit 1; }
    compose logs -f --tail 100 "$2"
    ;;
  wp)
    shift
    compose run --rm wp-cli wp "$@"
    ;;
  destruir)
    read -r -p "Esto borra TODOS los datos de la empresa. Escribe 'borrar' para seguir: " ok
    [[ "$ok" == "borrar" ]] && compose down -v || echo "Cancelado."
    ;;
  *)
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
    ;;
esac

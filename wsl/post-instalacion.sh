#!/usr/bin/env bash
# Prepara Debian en WSL 2 como servidor de administracion del laboratorio.
# Uso (dentro de Debian):  sudo wsl/post-instalacion.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo." >&2; exit 1; }
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source /etc/os-release
echo "Sistema actual: $PRETTY_NAME"

if [[ "$VERSION_CODENAME" == "bookworm" ]]; then
  echo "Actualizando Debian 12 (bookworm) a Debian 13 (trixie)..."
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
    [[ -f "$f" ]] && sed -i 's/bookworm/trixie/g' "$f"
  done
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade
fi

echo "Instalando herramientas de administracion..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  systemd systemd-sysv \
  git curl wget ca-certificates openssl \
  htop ncdu tree less vim nano jq \
  iproute2 iputils-ping dnsutils net-tools tcpdump traceroute nmap \
  default-mysql-client postgresql-client

install -m 644 wsl.conf /etc/wsl.conf

echo
echo "Listo. Ahora, en PowerShell de Windows, ejecuta:  wsl --shutdown"
echo "Al volver a abrir Debian tendras systemd y el nombre de equipo lab-andes."
if ! command -v docker >/dev/null; then
  echo "Falta Docker: en Docker Desktop > Settings > Resources > WSL integration, activa Debian."
fi

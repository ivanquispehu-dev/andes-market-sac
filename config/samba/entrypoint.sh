#!/usr/bin/env bash
# Primer arranque: crea el dominio ANDESMARKET.LOCAL y las cuentas de TI.
# Arranques siguientes: solo inicia Samba (los datos viven en volumenes).
set -euo pipefail

REALM="${SAMBA_REALM:-ANDESMARKET.LOCAL}"
DOMINIO="${SAMBA_DOMAIN:-ANDES}"
USUARIOS_CSV=/config/usuarios.csv

if [[ ! -f /var/lib/samba/private/sam.ldb ]]; then
  echo "Creando el dominio $REALM..."
  rm -f /etc/samba/smb.conf
  samba-tool domain provision \
    --realm="$REALM" \
    --domain="$DOMINIO" \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --use-rfc2307 \
    --adminpass="$SAMBA_ADMIN_PASSWORD" \
    --option="dns forwarder = 127.0.0.11"

  echo "Creando grupos y usuarios desde $USUARIOS_CSV..."
  tail -n +2 "$USUARIOS_CSV" | cut -d';' -f5 | sort -u | while read -r grupo; do
    samba-tool group add "$grupo" >/dev/null
    echo "  grupo $grupo"
  done
  tail -n +2 "$USUARIOS_CSV" | while IFS=';' read -r usuario nombre apellido area grupo; do
    samba-tool user create "$usuario" "$SAMBA_USERS_PASSWORD" \
      --given-name="$nombre" --surname="$apellido" --department="$area" \
      --mail-address="$usuario@andesmarket.local" \
      --must-change-at-next-login >/dev/null
    samba-tool group addmembers "$grupo" "$usuario" >/dev/null
    echo "  usuario $usuario ($grupo)"
  done
fi

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
echo "lim-dc-01 listo: dominio $REALM"
exec samba --foreground --no-process-group --debug-stdout

# lim-dc-01: controlador de dominio Samba AD sobre Debian 13
FROM debian:trixie

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      samba samba-ad-dc samba-ad-provision samba-dsdb-modules samba-vfs-modules \
      winbind krb5-user smbclient ldb-tools \
      dnsutils iproute2 iputils-ping procps \
 && rm -rf /var/lib/apt/lists/* \
 && mv /etc/samba/smb.conf /etc/samba/smb.conf.debian

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 53 53/udp 88 88/udp 135 389 389/udp 445 464 464/udp 636 3268 3269

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

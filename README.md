# AndesMarket S.A.C. · laboratorio de administración de sistemas

Simulación local de una empresa ficticia de comercio electrónico de Lima para
practicar administración de servidores, bases de datos y aplicaciones. Tú eres
administrador de sistemas del equipo de Infraestructura: cada día recibes un
ticket, lo resuelves y lo documentas como en una empresa real.

- Informe de la empresa (organigrama, servidores, procesos, escenarios):
  https://claude.ai/code/artifact/69b77814-55e5-4542-80b1-5629d8854bcf
- Informe de la simulación (herramientas, memoria, fases):
  https://claude.ai/code/artifact/1e14a337-ac46-4823-8352-6c085f5f57a3

## Cómo está armado

```
Windows 11 (12 GB)
└── WSL 2 (máximo 6 GB, ver wsl/wslconfig.example)
    ├── Debian 13 "lab-andes"   ← aquí administras: terminal, git, scripts
    └── Docker Desktop          ← aquí corren los servidores de la empresa
        ├── red andes-dmz         10.10.10.0/24  (pública)
        └── red andes-servidores  10.10.20.0/24  (interna, sin internet)
```

Servidores disponibles en la fase 1:

| Servidor | Función | IP | Imagen |
| --- | --- | --- | --- |
| lim-lb-01 | Nginx: HTTPS y reparto de tráfico | 10.10.10.10 | nginx:stable-alpine |
| lim-web-01 | Tienda WordPress + WooCommerce | 10.10.10.11 / 10.10.20.11 | wordpress:php8.3-apache |
| lim-web-02 | Segundo nodo de la tienda | 10.10.10.12 / 10.10.20.12 | wordpress:php8.3-apache |
| lim-db-02 | MySQL de la tienda | 10.10.20.22 | mysql:8.4 |
| lim-dc-01 | Samba AD: dominio ANDESMARKET.LOCAL, cuentas de TI | 10.10.20.41 | construida desde `config/samba` (Debian 13) |

## Puesta en marcha (fase 1)

### 1. Limitar la memoria de WSL

Copia `wsl/wslconfig.example` a `C:\Users\<tu-usuario>\.wslconfig` y en
PowerShell ejecuta `wsl --shutdown`. Sin este límite WSL puede usar la mitad de
tu RAM.

### 2. Instalar Debian en WSL

En PowerShell:

```powershell
wsl --install -d Debian
```

Crea tu usuario cuando lo pida. Luego, dentro de Debian, revisa la versión con
`cat /etc/os-release`. Si dice 12 (bookworm), el script del paso 4 la sube a 13.

### 3. Conectar Docker Desktop con Debian

En Docker Desktop: **Settings > Resources > WSL integration**, activa
**Debian** y pulsa *Apply & restart*. Comprueba en Debian con `docker version`.

### 4. Clonar este repositorio y preparar Debian

Clona dentro de Debian (no en `/mnt/c`, que es mucho más lento):

```bash
cd ~
git clone https://github.com/ivanquispehu-dev/andes-market-sac.git
cd andes-market-sac
sudo wsl/post-instalacion.sh
```

Después, en PowerShell, `wsl --shutdown` y vuelve a abrir Debian.

### 5. Levantar la empresa e instalar la tienda

```bash
./lab.sh iniciar 1
datos/instalar-tienda.sh
```

La primera vez, `lab.sh` construye la imagen de lim-dc-01 a partir de Debian 13
y crea el dominio con los 11 empleados de TI de `config/samba/usuarios.csv`.
Tarda unos minutos.

Abre https://localhost:8443. El navegador avisará que el certificado no es de
confianza: es autofirmado, acéptalo. El usuario y la clave del panel
(`/wp-admin`) están en el archivo `.env`.

## Comandos del día a día

| Comando | Para qué |
| --- | --- |
| `./lab.sh estado` | Ver servidores, salud y memoria |
| `./lab.sh logs lim-web-01` | Seguir los logs de un servidor |
| `docker exec -it lim-db-02 mysql -uroot -p` | Entrar a MySQL |
| `docker exec -it lim-web-01 bash` | Entrar a un servidor |
| `./lab.sh wp plugin list` | Administrar WordPress con wp-cli |
| `docker exec lim-dc-01 samba-tool user list` | Ver las cuentas del dominio |
| `docker exec -it lim-dc-01 samba-tool user create <usuario>` | Crear una cuenta |
| `./lab.sh detener` | Apagar todo (los datos se conservan) |

## Cómo se trabaja

Cada día llega un ticket en el hilo del proyecto. Lo registras con
`procesos/plantilla-ticket.md`, lo resuelves y respondes en el hilo con lo que
hiciste. Si el arreglo cambia producción, primero pides aprobación con
`procesos/plantilla-cambio.md`. Todo P1 termina en un postmortem con
`procesos/plantilla-postmortem.md`. Lo que aprendas va a `procesos/runbooks/`.

## Estructura

| Ruta | Contenido |
| --- | --- |
| `lab.sh` | Encender, apagar y ver el estado de la empresa |
| `.env.example` | Variables y contraseñas (se copia a `.env`, que no se sube a Git) |
| `wsl/` | Configuración de WSL 2 y preparación de Debian |
| `compose/fase1.yml` | Redes y servidores de la fase 1 |
| `config/nginx/` | Sitio HTTPS de la tienda y script del certificado |
| `config/mysql/` | Configuración de lim-db-02 |
| `config/samba/` | Imagen de lim-dc-01, creación del dominio y lista de empleados |
| `datos/instalar-tienda.sh` | WordPress, WooCommerce y productos de ejemplo |
| `procesos/` | Plantillas de ticket, cambio y postmortem; runbooks |

Próximas entregas: fase 2 (ERP Odoo,
almacén, réplica y respaldos), fase 3 (monitoreo, tickets en GLPI, fallas
simuladas) y fase 4 (Windows Server y pfSense).

# Pràctica: Servidor de Missatgeria Matrix amb Docker

## Objectius

En aquesta pràctica aprendràs a:

- Desplegar un servidor Matrix (Synapse) amb Docker
- Configurar un homeserver personalitzat amb el teu nom
- Instal·lar i utilitzar el client Element
- Crear usuaris i sales de xat
- Verificar xifrat d'extrem a extrem (E2EE)
- Configurar federació (opcional)
- Documentar la instal·lació i configuració

## Requisits

**Programari necessari:**
- Docker Desktop o Docker Engine
- Docker Compose
- Navegador web modern
- Editor de text (VS Code, Notepad++, nano)

**Coneixements previs:**
- Conceptes de missatgeria instantània
- Docker i contenidors
- Protocols de xarxa bàsics

## Què és Matrix?

Matrix és un protocol obert de comunicació en temps real, pensat per a xat, veu i vídeo, que destaca per ser descentralitzat i federat.

### Com funciona Matrix?

- Hi ha servidors (homeservers)
- Hi ha clients
- Els servidors es federen entre ells

Exemple d'usuari: `@usuari:exemple.cat`

### Components principals

- **Homeserver**: El servidor Matrix que gestiona els usuaris i les sales.
  - Exemples: Synapse, Dendrite, Conduit
- **Client**: L'aplicació que utilitza l'usuari per connectar-se al servidor.
  - Exemples: Element, FluffyChat, Nheko
- **Sales (Rooms)**: Espais on es duen a terme les converses.
  - Exemple: `!abc123:exemple.cat`

## Part 1: Preparació de l'Entorn

### Pas 1.1: Crear estructura de directoris

Crea un directori de treball personalitzat amb el teu nom i cognom:

```bash
mkdir -p ~/matrix-NOMCOGNOM
cd ~/matrix-NOMCOGNOM
mkdir -p data config
````

### Pas 1.2: Generar fitxer de configuració inicial

Utilitzarem el contenidor oficial de Synapse per generar una configuració base:

```bash
docker run -it --rm \
  -v $(pwd)/data:/data \
  -e SYNAPSE_SERVER_NAME=matrix.NOMCOGNOM.local \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

Això crearà `data/homeserver.yaml` amb la configuració base.

## Part 2: Configuració de Synapse

### Pas 2.1: Editar `homeserver.yaml`

Edita el fitxer generat `data/homeserver.yaml` i personalitza els següents paràmetres:

```yaml
server_name: "matrix.NOMCOGNOM.local"
enable_registration: true
enable_registration_without_verification: true
database:
  name: sqlite3
  args:
    database: /data/homeserver.db
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['::']
resources:
  - names: [client, federation]
    compress: false
public_baseurl: "http://matrix.NOMCOGNOM.local:8008"
admin_contact: "mailto:NOMCOGNOM@sapalomera.cat"
encryption_enabled_by_default_for_room_type: all
max_upload_size: 50M
log_config: "/data/matrix.NOMCOGNOM.local.log.config"
```

### Pas 2.2: Configurar logs

Edita el fitxer `data/matrix.NOMCOGNOM.local.log.config` per configurar el registre d'activitat:

```yaml
version: 1
formatters:
  precise:
    format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(message)s'
handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
    level: INFO
  file:
    class: logging.handlers.RotatingFileHandler
    formatter: precise
    filename: /data/homeserver.log
    maxBytes: 10485760
    backupCount: 3
    level: INFO
root:
  level: INFO
  handlers: [console, file]
```

## Part 3: Docker Compose

### Pas 3.1: Crear `docker-compose.yml`

Crea el fitxer `docker-compose.yml` personalitzat:

```yaml
services:
  synapse-NOMCOGNOM:
    image: matrixdotorg/synapse:latest
    container_name: matrix-synapse-NOMCOGNOM
    ports:
      - "8008:8008"
    volumes:
      - ./data:/data
    environment:
      - SYNAPSE_SERVER_NAME=matrix.NOMCOGNOM.local
      - SYNAPSE_REPORT_STATS=no
      - TZ=Europe/Madrid
    restart: unless-stopped
    networks:
      - matrix-network
  element-NOMCOGNOM:
    image: vectorim/element-web:latest
    container_name: matrix-element-NOMCOGNOM
    ports:
      - "8080:80"
    volumes:
      - ./config/element-config.json:/app/config.json:ro
    restart: unless-stopped
    depends_on:
      - synapse-NOMCOGNOM
    networks:
      - matrix-network
networks:
  matrix-network:
    driver: bridge
```

### Pas 3.2: Configurar Element

Crea el fitxer `config/element-config.json` personalitzat:

```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "http://matrix.NOMCOGNOM.local:8008",
      "server_name": "matrix.NOMCOGNOM.local"
    }
  },
  "brand": "Element - Matrix NOMCOGNOM",
  "default_country_code": "ES",
  "show_labs_settings": true,
  "default_theme": "light",
  "room_directory": {
    "servers": ["matrix.NOMCOGNOM.local"]
  },
  "enable_presence_by_hs_url": {
    "http://matrix.NOMCOGNOM.local:8008": true
  },
  "setting_defaults": {
    "breadcrumbs": true
  }
}
```

## Part 4: Desplegament i Verificació

### Pas 4.1: Iniciar els serveis

```bash
docker-compose up -d
docker-compose ps
```

### Pas 4.2: Verificar logs

```bash
docker-compose logs synapse-NOMCOGNOM
docker-compose logs -f synapse-NOMCOGNOM
```

### Pas 4.3: Accedir a Element

Obre el navegador i accedeix a:

```
http://matrix.NOMCOGNOM.local:8080
```

## Part 5: Creació d'Usuaris

### Pas 5.1: Registrar el primer usuari (admin)

A la interfície d'Element, clica "Create Account" i registra't com a admin.

### Pas 5.2: Crear usuaris addicionals

Crea almenys 2 usuaris més per provar la missatgeria.

## Part 6: Proves de Funcionalitat

### Pas 6.1: Crear una sala de xat

Crea una sala de xat amb E2EE activat.

### Pas 6.2: Convidar altres usuaris

Invita els usuaris creats a la sala.

### Pas 6.3: Provar missatgeria E2EE

Verifica el xifrat E2EE i envia missatges entre usuaris.

## Part 7: Funcionalitats Avançades

* **Compartir fitxers**
* **Formatar missatges**
* **Reaccions i respostes**

## Part 8: Administració del Servidor

### Pas 8.1: Desactivar registre obert

Desactiva el registre públic editant el fitxer `homeserver.yaml`.

### Pas 8.2: Consultar base de dades

Explora la base de dades SQLite amb les comandes SQL.

### Pas 8.3: Monitoritzar recursos

```bash
docker stats
tail -f data/homeserver.log
```

## Qüestions i Exercicis

Contesta les qüestions i realitza els exercicis opcionals.

## Conclusió

Amb aquesta pràctica, has aconseguit desplegar un servidor Matrix completament funcional amb Docker, configurar la seguretat amb E2EE, i personalitzar la configuració amb el teu nom. Això et permetrà tenir un control total sobre la teva missatgeria i mantenir la teva comunicació privada i segura.

````markdown
# Servidor de Missatgeria Matrix amb Docker
Aquest projecte desplega un servidor de missatgeria Matrix utilitzant Docker i Docker Compose. Es fa servir Synapse com a homeserver i Element com a client web per interactuar amb el servidor.
## Requisits previs
Abans de començar, assegura't que tens instal·lat el següent:
- **Docker** i **Docker Compose**: Per gestionar els contenidors.
- **Un navegador web modern**: Per accedir al client web Element.
- **Un editor de text** (per exemple, VS Code, Notepad++, nano): Per editar fitxers de configuració.
## Passos per posar en marxa el projecte
### 1. Crear l'estructura de directoris
Crea un directori de treball personalitzat per al projecte i entra dins d'ell:
```bash
mkdir -p ~/matrix-NOMCOGNOM
cd ~/matrix-NOMCOGNOM
mkdir -p data config
````

Substitueix `NOMCOGNOM` pel teu nom i cognom (tot en minúscules).

### 2. Generar la configuració inicial de Synapse

Utilitza el contenidor oficial de Synapse per generar la configuració base:

```bash
docker run -it --rm \
  -v $(pwd)/data:/data \
  -e SYNAPSE_SERVER_NAME=matrix.NOMCOGNOM.local \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

Això generarà un fitxer `homeserver.yaml` dins del directori `data`.

### 3. Editar la configuració de Synapse

Obre el fitxer `data/homeserver.yaml` i personalitza els següents paràmetres:

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

### 4. Configurar logs

Obre el fitxer `data/matrix.NOMCOGNOM.local.log.config` i ajusta la configuració dels logs:

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

### 5. Crear el fitxer `docker-compose.yml`

Crea el fitxer `docker-compose.yml` amb la següent configuració:

```yaml
version: '3'

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

### 6. Configurar Element

Crea el fitxer `config/element-config.json` amb la següent configuració:

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

### 7. Iniciar els contenidors

Inicia els contenidors amb Docker Compose:

```bash
docker-compose up -d
```

Verifica que els contenidors estiguin actius:

```bash
docker-compose ps
```

Deuries veure que tant el servidor Synapse com el client Element estan en funcionament.

### 8. Accedir a Element

Obre un navegador i accedeix a la següent URL per obrir el client web Element:

```
http://matrix.NOMCOGNOM.local:8080
```

### 9. Registrar el primer usuari (admin)

A la interfície web d'Element, clica "Create Account" i registra el teu primer usuari com a administrador. Utilitza el teu nom o el que vulguis per al nom d'usuari.

### 10. Crear usuaris addicionals

Des de la interfície d'Element o des del terminal, crea almenys dos usuaris més per provar la missatgeria:

```bash
docker exec -it matrix-synapse-NOMCOGNOM \
  register_new_matrix_user \
  http://matrix.NOMCOGNOM.local:8008 \
  -c /data/homeserver.yaml \
  -u NOMCOGNOM-user1 \
  -p ContraForta123! \
  --admin
```

### 11. Crear una sala de xat

Des de la interfície d'Element, crea una nova sala de xat amb la configuració següent:

* **Nom de la sala**: Sala de NOMCOGNOM
* **Visibilitat**: Private
* **Activar xifrat E2EE**: Activat

### 12. Convidar altres usuaris a la sala

Invita els usuaris que has creat a la sala que acabes de crear.

### 13. Verificar el xifrat E2EE

Verifica que el xifrat d'extrem a extrem (E2EE) estigui activat i que els missatges siguin segurs.

### 14. Desactivar el registre obert (opcional)

Després de crear els usuaris necessaris, desactiva el registre públic al fitxer `homeserver.yaml`:

```yaml
enable_registration: false
```

Reinicia el contenidor Synapse per aplicar els canvis:

```bash
docker-compose restart synapse-NOMCOGNOM
```

## Recursos addicionals

* [Documentació oficial de Synapse](https://matrix.org/docs/projects/server/synapse)
* [Documentació oficial d'Element](https://element.io/docs)
* [Matrix Specification](https://spec.matrix.org/)
  Ara tens un servidor Matrix completament funcional amb Docker, amb la seguretat d'E2EE i amb un client Element per interactuar amb ell. Amb aquesta infraestructura, pots començar a utilitzar Matrix per a la teva comunicació privada i segura.

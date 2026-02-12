# SOC - Guía de Configuración Avanzada

## 📚 Tabla de Contenidos
1. [Seguridad](#seguridad)
2. [Performance](#performance)
3. [Integración LDAP](#integración-ldap)
4. [Backup y Recuperación](#backup-y-recuperación)
5. [Custom Rules](#custom-rules)
6. [Monitoring y Alertas](#monitoring-y-alertas)

---

## 🔐 Seguridad

### Habilitar SSL/TLS en Elasticsearch

1. Generar certificados:

```bash
docker exec soc4-elasticsearch bin/elasticsearch-certutil ca --silent --pem --out-folder /usr/share/elasticsearch/config/certs
docker exec soc4-elasticsearch bin/elasticsearch-certutil cert --silent --pem --ca-cert /usr/share/elasticsearch/config/certs/ca/ca.crt --ca-key /usr/share/elasticsearch/config/certs/ca/ca.key --out-folder /usr/share/elasticsearch/config/certs
```

2. Actualizar docker-compose.yml:

```yaml
elasticsearch:
  environment:
    - xpack.security.http.ssl.enabled=true
    - xpack.security.http.ssl.key=/usr/share/elasticsearch/config/certs/instance/instance.key
    - xpack.security.http.ssl.certificate=/usr/share/elasticsearch/config/certs/instance/instance.crt
    - xpack.security.http.ssl.certificate_authorities=/usr/share/elasticsearch/config/certs/ca/ca.crt
```

### Habilitar Autenticación en Elasticsearch

```yaml
elasticsearch:
  environment:
    - xpack.security.enabled=true
    - xpack.security.enrollment.enabled=true
```

### Configurar Contraseña de Elasticsearch

```bash
# Configurar contraseña del usuario elastic
docker exec soc4-elasticsearch elasticsearch-reset-password -u elastic --interactive

# Usar contraseña en conexiones
curl -u elastic:PASSWORD http://localhost:9200/_cluster/health
```

---

## ⚡ Performance

### Tuning de Elasticsearch

**Archivo**: `ELK/logstash/config/logstash.yml`

```yaml
# Aumentar memoria si es posible
ES_JAVA_OPTS: -Xms2g -Xmx2g

# Configuración de índices
elasticsearch:
  index_settings:
    number_of_shards: 5
    number_of_replicas: 1
```

### Tuning de Logstash

```yaml
# Aumentar workers
pipeline.workers: 8  # Por defecto 4

# Aumentar batch size
pipeline.batch.size: 1024  # Por defecto 512

# Reducir latencia
pipeline.batch.delay: 5  # milisegundos
```

### Tuning de Filebeat

```yaml
# Aumentar número de workers
filebeat.inputs:
  - type: log
    worker: 4
    
# Aumentar bulk size
output.logstash:
  bulk_max_size: 4096
```

### Monitoreo de Performance

```bash
# Ver métricas de Elasticsearch
curl http://localhost:9200/_nodes/stats?pretty | jq '.nodes'

# Ver estado de índices
curl http://localhost:9200/_cat/indices?v

# Monitor de JVM en Elasticsearch
curl http://localhost:9200/_nodes/jvm?pretty
```

---

## 🔑 Integración LDAP

### Configurar LDAP en TheHive

Actualizar `thehive/config/application.conf`:

```properties
auth {
  type = "ldap"
  provider = "ldap"
  ldap {
    enable = true
    url = "ldap://ldap-server:389"
    baseDN = "ou=users,dc=example,dc=com"
    filter = "(uid={0})"
    usernameAttribute = "uid"
    groupAttribute = "memberOf"
    
    # Usuario con permisos de lectura en LDAP
    bindDN = "cn=admin,dc=example,dc=com"
    bindPassword = "password"
    
    # Atributos de usuario
    mail = "mail"
    name = "cn"
    
    # Timeout
    timeout = 10000
    
    # SSL (opcional)
    # useSSL = true
    # useTLS = false
  }
}
```

### Probar conexión LDAP

```bash
# Desde el contenedor de TheHive
docker exec soc4-thehive ldapsearch -x -H ldap://ldap-server:389 \
  -b "dc=example,dc=com" \
  -D "cn=admin,dc=example,dc=com" \
  -w password
```

---

## 💾 Backup y Recuperación

### Backup Manual de Elasticsearch

```bash
#!/bin/bash
# backup-elasticsearch.sh

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/elasticsearch_backup_$TIMESTAMP.json"

mkdir -p $BACKUP_DIR

# Hacer dump de todos los índices
docker exec soc4-elasticsearch elasticdump \
  --input http://localhost:9200 \
  --output "$BACKUP_FILE" \
  --type data

echo "Backup creado: $BACKUP_FILE"
```

### Restaurar desde Backup

```bash
# Restaurar datos
docker exec soc4-elasticsearch elasticdump \
  --input "backup_file.json" \
  --output http://localhost:9200 \
  --type data
```

### Snapshot de Elasticsearch

```bash
# Registrar repositorio de snapshots
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d '{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/snapshots"
  }
}'

# Crear snapshot
curl -X PUT "localhost:9200/_snapshot/my_backup/snapshot_1"

# Listar snapshots
curl -X GET "localhost:9200/_snapshot/my_backup/_all"

# Restaurar snapshot
curl -X POST "localhost:9200/_snapshot/my_backup/snapshot_1/_restore"
```

### Backup de TheHive

```bash
# Los datos de TheHive se almacenan en Elasticsearch
# Por lo tanto, un backup de Elasticsearch incluye toda la información de TheHive

# Backup manual de la configuración
docker cp soc4-thehive:/etc/thehive ./thehive_config_backup/
```

---

## 📝 Custom Rules

### Crear Regla de ElastAlert Avanzada

Archivo: `elastalert/rules/custom-rule.yaml`

```yaml
name: "Detección de Port Scanning"
description: "Detecta intentos de escaneo de puertos"
type: frequency
index: logs-*

# Parámetros de detección
num_events: 10
timeframe:
  minutes: 5

# Filtro
filter:
  - query:
      query_string:
        query: 'message:("Connection refused" OR "Connection timeout") AND tags:network'

# Agregación por IP origen
aggregation:
  - terms:
      size: 10
      field: source_ip

# Alertas
alert:
  - hivealerter
  - email

# Configuración de TheHive
hive_connection:
  hive_host: http://thehive
  hive_port: 9000
  hive_apikey: "YOUR_API_KEY"
  hive_verify: false

hive_alert_config:
  title: "Port Scanning Detected from {agg_data[0][0]}"
  type: "alert"
  source: "ElastAlert"
  severity: 2
  tlp: 2
  tags: ["network", "port-scan", "reconnaissance"]

# Correo
email: ["soc-alerts@company.com"]
from_addr: elastalert@company.com
smtp_host: localhost

# Mensaje personalizado
alert_text: |
  Potencial Port Scanning Detectado
  
  IP Origen: {agg_data[0][0]}
  Conexiones Rechazadas: {num_matches}
  Timeframe: {timeframe}
  
  Timestamp: {match_time}
  
  Recomendación: Investigar la IP y considerar bloquear si es maliciosa
```

### Crear Regla con Machine Learning

```yaml
name: "Anomalía en Volumen de Logs"
type: spike
index: logs-*

spike_height: 2  # El doble del normal
spike_type: "up"
timeframe:
  minutes: 10

threshold_ref:
  days: 7
  
threshold_cur:
  minutes: 10

alert:
  - hivealerter
```

---

## 📊 Monitoring y Alertas

### Crear Dashboard de Health Check

En Kibana:

1. Ve a **Visualize** → **Create visualization**
2. Elige "Gauge" (Medidor)
3. Configura la métrica para el estado de servicios

```json
{
  "metric": {
    "buckets": [
      {
        "field": "service_status",
        "value": 1
      }
    ]
  }
}
```

### Alertas de Kibana

1. Ve a **Stack Management** → **Alerting**
2. Create new alert rule
3. Configura condiciones

```
IF (count of logs) GREATER THAN 1000
OVER LAST 5 minutes
THEN send email to soc@company.com
```

### Metricas Custom en Logstash

```ruby
filter {
  # Contar eventos por tipo
  if [event_type] {
    mutate {
      add_field => { "[@metadata][metrics]" => "%{event_type}" }
    }
  }
  
  # Tracking de latencia
  ruby {
    code => 'event.set("processing_time", Time.now.to_f * 1000 - event.get("@timestamp").to_f * 1000)'
  }
}
```

### Cuotas de Almacenamiento

```bash
# Ver uso de espacio por índice
curl http://localhost:9200/_cat/indices?v | grep -o "^[^ ]*" | while read idx; do
  size=$(curl -s "http://localhost:9200/$idx/_stats" | jq '.indices.'$idx'.primaries.store.size_in_bytes')
  echo "$idx: $size bytes"
done

# Eliminar índices antiguos
curl -X DELETE "http://localhost:9200/logs-$(date -d '30 days ago' +%Y.%m.%d)"
```

---

## 🔍 Debugging

### Habilitar Debug en Componentes

**Logstash**:
```yaml
logger.logstash.core: DEBUG
logger.logstash.runner: DEBUG
```

**Filebeat**:
```yaml
logging.level: debug
```

**TheHive**:
```properties
logger.thehive: DEBUG
```

### Ver Logs en Tiempo Real

```bash
# Todos los servicios
docker-compose logs -f

# Servicio específico
docker-compose logs -f elasticsearch

# Últimas 100 líneas
docker-compose logs --tail=100 elasticsearch
```

### Ejecutar Comandos en Contenedores

```bash
# Bash en Elasticsearch
docker exec -it soc4-elasticsearch bash

# Python en Cortex
docker exec -it soc4-cortex python3

# Node en ElastAlert
docker exec -it soc4-elastalert bash
```

---

## 📞 Recursos Adicionales

- Documentación Elasticsearch: https://www.elastic.co/guide/en/elasticsearch/reference/
- Documentación TheHive: https://docs.thehive-project.org/
- ElastAlert2: https://github.com/jertel/elastalert2
- Cortex Analyzers: https://github.com/TheHive-Project/Cortex-Analyzers

---

**Última Actualización**: 11 de febrero de 2026

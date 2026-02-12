# 🔍 SOC - Referencia de Búsquedas y Queries

## 📚 Tabla de Contenidos
1. [Búsquedas en Kibana](#búsquedas-en-kibana)
2. [Elasticsearch Queries](#elasticsearch-queries)
3. [Patrones de Seguridad](#patrones-de-seguridad)
4. [Análisis Forense](#análisis-forense)
5. [Performance Tuning](#performance-tuning)

---

## 🎯 Búsquedas en Kibana

### Sintaxis Básica

```
# AND
campo:valor AND otro_campo:valor2

# OR
campo:valor1 OR campo:valor2

# NOT
campo:valor AND NOT otro_campo:valor2

# Comodín
campo:val*

# Rango
timestamp:[2024-01-01 TO 2024-01-31]
http_code:[400 TO 599]
```

### Búsquedas por Tipo de Log

#### Sistema Linux
```
tags:system
tags:auth
tags:linux

# Más específico
tags:auth AND message:failed
tags:system AND syslog_priority:error
```

#### Web Servers
```
tags:webserver
tags:apache
tags:nginx

# Códigos HTTP
http_code:500
http_code:[400 TO 499]
http_code:[200 TO 299]

# Métodos HTTP
method:POST
method:DELETE
```

#### Docker
```
tags:docker
tags:container
container_name:soc4-*

# Por servicio
container_name:soc4-elasticsearch
container_name:soc4-thehive
```

---

## 🔐 Patrones de Seguridad

### Detección de Intrusiones

#### Port Scanning
```
message:("Connection refused" OR "Connection timeout" OR "refused by server")
AND (source_ip:* OR client_ip:*)
```

#### Inyección SQL
```
message:(
  "' OR '1'='1" OR 
  "union select" OR 
  "drop table" OR 
  "exec(" OR 
  "execute("
)
AND tags:webserver
```

#### Cross-Site Scripting (XSS)
```
message:(
  "<script" OR 
  "javascript:" OR 
  "onerror=" OR 
  "onclick="
)
AND tags:webserver
```

#### Command Injection
```
message:(
  "cmd.exe" OR 
  "/bin/sh" OR 
  "bash -i" OR 
  "nc.exe" OR 
  "powershell.exe"
)
```

#### Path Traversal
```
message:(
  "../" OR 
  "..%" OR 
  "..;" OR 
  "..../"
)
AND tags:webserver
```

### Detección de Malware

#### Descarga de Ejecutables
```
message:(
  ".exe" OR 
  ".msi" OR 
  ".dll" OR 
  ".scr" OR 
  ".bat"
) 
AND tags:webserver
```

#### Modificación de Archivos del Sistema
```
message:(
  "chmod 777" OR 
  "chown" OR 
  "chattr"
)
AND tags:system
```

### Monitoreo de Acceso

#### Intentos de Logeo Fallidos
```
tags:auth AND (
  message:"failed password" OR 
  message:"authentication failure" OR 
  message:"login attempt failed" OR 
  message:"invalid credentials"
)
```

#### Escalación de Privilegios
```
message:(
  "sudo" OR 
  "sudoedit" OR 
  "sudo: "
)
AND tags:system
```

#### Acceso a Directorios Sensibles
```
path:(
  "/etc/shadow" OR 
  "/etc/passwd" OR 
  "/root/" OR 
  "C:\\Windows\\System32"
)
```

---

## 📊 Análisis Forense

### Por Dirección IP

#### Actividad de una IP específica
```
source_ip:192.168.1.100 OR client_ip:192.168.1.100
```

#### Top 10 IPs con más conexiones
En Kibana: Visualize → Pie Chart → Aggregation: source_ip

#### Geolocalización de IPs
```
geoip.location:(* NOT null)
```

### Por Usuario/Credenciales

#### Intentos de acceso por usuario
```
user:* AND message:authentication
```

#### Usuarios conectados en el último día
```
tags:auth AND @timestamp:[now-24h TO now] 
AND (message:"Accepted" OR message:"logged in")
```

### Por Tipo de Evento

#### Cambios de configuración
```
message:(
  "config changed" OR 
  "settings modified" OR 
  "policy update"
)
```

#### Acceso a archivos sensibles
```
file_name:(
  "passwd" OR 
  "shadow" OR 
  "sudoers"
)
```

---

## 📈 Performance y Métricas

### Monitoreo de Carga

#### Eventos por hora
```json
{
  "aggs": {
    "events_per_hour": {
      "date_histogram": {
        "field": "@timestamp",
        "calendar_interval": "1h"
      }
    }
  }
}
```

#### Promedio de latencia
```
query:*
aggregation: avg(@timestamp)
```

### Análisis de Recursos

#### Procesos por memoria utilizada
```
process_name:* AND memory_bytes:[1000000 TO *]
```

#### Conexiones de red abiertas
```
network_status:established OR network_status:listening
```

---

## 🔍 Elasticsearch Queries Avanzadas

### Búsqueda de Texto Completo

```bash
# Endpoint
GET /logs-*/_search

# Query body
{
  "query": {
    "multi_match": {
      "query": "error exception",
      "fields": ["message", "log_message", "error_text"]
    }
  }
}
```

### Rango de Fechas

```bash
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "2024-01-01",
        "lte": "2024-01-31",
        "format": "yyyy-MM-dd"
      }
    }
  }
}
```

### Términos Comunes

```bash
{
  "query": {
    "terms": {
      "http_code": [400, 401, 403, 404, 500, 502, 503]
    }
  }
}
```

### Agregación por Rango

```bash
{
  "aggs": {
    "response_codes": {
      "range": {
        "field": "http_code",
        "ranges": [
          { "to": 300 },
          { "from": 300, "to": 400 },
          { "from": 400, "to": 500 },
          { "from": 500 }
        ]
      }
    }
  }
}
```

### Búsqueda Booleana Compleja

```bash
{
  "query": {
    "bool": {
      "must": [
        { "match": { "tags": "webserver" } }
      ],
      "should": [
        { "match": { "http_code": 404 } },
        { "match": { "http_code": 500 } }
      ],
      "must_not": [
        { "match": { "source_ip": "192.168.1.1" } }
      ],
      "minimum_should_match": 1
    }
  }
}
```

---

## 🎯 Casos de Uso Comunes

### 1. Investigación de Incidente

```
# Buscar todos los eventos de un usuario sospechoso
user:"admin" AND @timestamp:[now-7d TO now]

# Combinado con IP
user:"admin" AND source_ip:10.0.0.*

# Durante un período específico
@timestamp:[2024-01-15T08:00:00 TO 2024-01-15T18:00:00]
```

### 2. Análisis de Disponibilidad

```
# Errores por servicio
tags:docker AND (message:error OR message:exception)

# HTTP 5xx errors
http_code:[500 TO 599]

# Tiempo de respuesta alto
response_time_ms:[5000 TO *]
```

### 3. Auditoría de Cambios

```
# Cambios de propietario de archivos
message:chown OR message:chattr

# Instalación de paquetes
message:"apt-get" OR message:"yum install"

# Cambios en sudoers
file_path:/etc/sudoers
```

### 4. Monitoreo de Seguridad

```
# Intentos de acceso root
user:root AND (message:fail* OR message:error)

# Puertos abiertos inusualmente
network.port:[50000 TO 65535]

# DNS queries sospechosas
protocol:dns AND (query_name:*.tk OR query_name:*.ml)
```

---

## 📊 Dashboards Recomendados

### Dashboard 1: Resumen Diario
- Eventos procesados (Línea)
- Errores vs éxito (Pie chart)
- Top 5 hosts (Tabla)
- Tasa de eventos/segundo (Gauge)

### Dashboard 2: Seguridad
- Intentos fallidos de auth (Línea)
- IPs sospechosas (Mapa)
- Cambios de privilegios (Tabla)
- Patrones de ataque detectados (Contador)

### Dashboard 3: Performance
- Latencia promedio (Gauge)
- Disk usage (Gauge)
- Memory utilization (Línea)
- Error rate (Línea)

---

## 💾 Exportar Resultados

### CSV desde Kibana
1. Discover → Seleccionar campos
2. Click en campo → Add to table
3. Click en options → Download CSV

### JSON desde Elasticsearch
```bash
curl "http://localhost:9200/logs-*/_search?pretty&size=10000" > results.json
```

### Script de Exportación
```bash
#!/bin/bash
curl -X GET "localhost:9200/logs-$(date +%Y.%m.%d)/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 10000,
    "query": {
      "range": {
        "@timestamp": {
          "gte": "now-1d"
        }
      }
    }
  }' > export_$(date +%Y%m%d_%H%M%S).json
```

---

## 🔔 Alertas Útiles en Kibana

### Crear Alerta de Email
1. **Stack Management** → **Rules and Connectors**
2. **Create Rule** → **Threshold Rule**
3. Configurar:
   - Condición: Count > 100
   - Timeframe: 1 hour
   - Destinatario: email

### Ejemplo: Alerta de Errores
```
Cuando (count of logs) MAYOR que 1000
Sobre últimas 5 minutos
Entonces enviar email a soc@company.com
```

---

## 📚 Operadores Especiales

```
# Existencia de campo
field:*  (campo existe)
NOT field:*  (campo no existe)

# Valores vacíos
field:""

# Rango de números
campo:[1 TO 10]
campo:[10 TO *]
campo:[* TO 10]

# Proximidad
"texto cercano"~5

# Wildcard
campo:hol*
campo:*ello
```

---

**Última Actualización**: 11 de febrero de 2026
**Versión**: 1.0

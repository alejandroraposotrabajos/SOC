# SOC - Guía de Operación y Administración

## 📋 Tabla de Contenidos
1. [Descripción General](#descripción-general)
2. [Arquitectura](#arquitectura)
3. [Inicio Rápido](#inicio-rápido)
4. [Componentes Detallados](#componentes-detallados)
5. [Operación del SOC](#operación-del-soc)
6. [Troubleshooting](#troubleshooting)
7. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Descripción General

El SOC (Security Operations Center) es una plataforma integrada de ciberseguridad que combina:

- **ELK Stack**: Recolección, procesamiento y visualización de logs
- **TheHive**: Gestión de casos de seguridad
- **Cortex**: Análisis automatizado de artefactos
- **ElastAlert**: Motor de detección de amenazas basado en reglas

### Flujo de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│                        SOURCES                                  │
│ (Linux logs, Web servers, Docker containers, syslog)            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  FILEBEAT   │ (Agent recolector)
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  LOGSTASH   │ (Procesamiento/Filtrado)
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
    ┌─────────────┐ ┌──────────────┐ ┌─────────────┐
    │ELASTICSEARCH│ │   KIBANA     │ │ ELASTALERT  │
    │ (Base Datos)│ │ (Visualización)│ │  (Alertas)  │
    └──────┬──────┘ └──────────────┘ └──────┬──────┘
           │                                 │
           └─────────────────┬───────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  CORTEX/THEHIVE  │ (Investigación)
                    │  (Análisis)      │
                    └──────────────────┘
```

---

## 🏗️ Arquitectura

### Componentes Principales

#### 1. **Elasticsearch** (Puerto 9200)
- Base de datos nosql para almacenamiento de logs
- Indización de alto rendimiento
- Búsqueda full-text

#### 2. **Logstash** (Puerto 5000, 5001)
- Procesamiento de logs en tiempo real
- Filtros de seguridad automatizados
- Enriquecimiento de datos

#### 3. **Kibana** (Puerto 5601)
- Visualización de logs
- Dashboards interactivos
- Análisis de tendencias

#### 4. **Filebeat** (Agente)
- Recolección de logs del sistema
- Monitoreo de contenedores Docker
- Envío a Logstash

#### 5. **TheHive** (Puerto 9000)
- Gestión de casos de seguridad
- Colaboración entre analistas
- Integración con Cortex

#### 6. **Cortex** (Puerto 9001)
- Análisis automatizado de artefactos
- Integración de herramientas de seguridad
- Respuesta automática a incidentes

#### 7. **ElastAlert** (Automático)
- Detección de patrones en logs
- Generación automática de alertas
- Creación de casos en TheHive

---

## 🚀 Inicio Rápido

### En Windows (PowerShell)

```powershell
# Ir al directorio del proyecto
cd "E:\Clase\INC\SOC 4"

# Iniciar el SOC
.\scripts\Start-SOC.ps1

# Verificar estado
.\scripts\Health-Check.ps1

# Detener el SOC
.\scripts\Stop-SOC.ps1
```

### En Linux/macOS (Bash)

```bash
# Ir al directorio del proyecto
cd /ruta/al/SOC

# Iniciar el SOC
bash scripts/start-soc.sh

# Verificar estado
bash scripts/health-check.sh

# Detener el SOC
bash scripts/stop-soc.sh
```

### Acceso a la Web

Una vez iniciado, accede a:

```
Kibana:      http://localhost:5601
Elasticsearch: http://localhost:9200
TheHive:     http://localhost:9000
Cortex:      http://localhost:9001
Logstash:    http://localhost:9600
```

---

## 📊 Componentes Detallados

### Elasticsearch

#### Endpoints Útiles

```bash
# Verificar salud del cluster
curl http://localhost:9200/_cluster/health

# Listar índices
curl http://localhost:9200/_cat/indices

# Ver mappings de un índice
curl http://localhost:9200/logs-*/_mapping

# Estadísticas de almacenamiento
curl http://localhost:9200/_cat/shards
```

#### Políticas de Índices

Los índices se crean automáticamente con rotación diaria:
- Formato: `logs-YYYY.MM.dd`
- Retención: Configurable mediante ILM
- Tamaño: Limitado por políticas de espacio

### Logstash

#### Monitoreo

```bash
# Ver estado de Logstash
curl http://localhost:9600/_node/stats

# Ver pipelines activos
curl http://localhost:9600/_node/pipelines
```

#### Archivo de Configuración

**Ubicación**: `ELK/logstash/pipeline/logstash.conf`

**Secciones**:
1. **Input**: Recibe datos de Beats y TCP/UDP
2. **Filter**: Procesa, filtra y enriquece datos
3. **Output**: Envía a Elasticsearch y alertas de seguridad

### Kibana

#### Dashboards Incluidos

El sistema incluye dashboards pre-configurados:
- Resumen de logs
- Análisis de seguridad
- Tráfico de red

#### Crear Visualizaciones

1. Ve a **Visualize** → **Create visualization**
2. Selecciona el tipo (área, línea, tabla, etc.)
3. Elige el índice (logs-*)
4. Configura filtros y agregaciones
5. Guarda

### FileBeate

#### Configuración

**Ubicación**: `agents/filebeat/filebeat.yml`

**Módulos habilitados**:
- Logs del sistema (syslog, auth)
- Logs de aplicaciones (Apache, Nginx)
- Logs de Docker (contenedores)

#### Agregar Nuevas Fuentes

```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /ruta/a/logs/*.log
    fields:
      log_source: mi_aplicacion
    tags: ["aplicacion"]
```

### TheHive

#### Acceso Inicial

- **URL**: http://localhost:9000
- **Usuario por defecto**: Configurar en primera ejecución
- **Contraseña**: Se asigna en el setup

#### Crear un Caso

1. Ve a **New Case**
2. Completa los campos:
   - Title
   - Description
   - Severity (Low, Medium, High, Critical)
   - TLP (White, Green, Amber, Red)
   - Tags
3. Guarda

#### Agregar Observables

En un caso abierto:
1. Ve a **Observables**
2. Click en **+ Add Observable**
3. Elige el tipo (IP, hash, email, etc.)
4. Ingresa el valor
5. **Run responders** para análisis automático con Cortex

### Cortex

#### Analizadores Disponibles

Los analizadores se instalan automáticamente:
- VirusTotal (análisis de malware)
- AbuseIPDB (reputación de IPs)
- Whois (información de dominio)
- MaxMind (geolocalización)

#### Configurar Cortex en TheHive

1. En TheHive, ve a **Admin** → **Cortex**
2. Ingresa URL de Cortex: `http://cortex:9001`
3. Genera y configura API key
4. Prueba la conexión

### ElastAlert

#### Reglas Configuradas

El sistema incluye 4 reglas de alerta:

1. **thehive-rule.yaml**: Alertas críticas a TheHive
2. **suspicious-web-activity.yaml**: Detección de inyecciones
3. **brute-force-detection.yaml**: Ataques de fuerza bruta
4. **privilege-escalation.yaml**: Cambios de privilegios

#### Crear Nueva Regla

1. Crea archivo en `elastalert/rules/mi-regla.yaml`

```yaml
name: Mi Regla de Alerta
type: frequency
index: logs-*
num_events: 5
timeframe:
  minutes: 10

filter:
  - query:
      query_string:
        query: 'field:value'

alert:
  - hivealerter
  - email

email: ["soc@company.com"]
```

2. Reinicia ElastAlert: `docker-compose restart elastalert`

---

## 🎮 Operación del SOC

### Flujo Típico de Trabajo

#### 1. **Monitoreo** (Kibana)

Accede a Kibana y crea dashboards para monitorear:
- Volumen de eventos por hora
- Errores y excepciones
- IPs con mayor tráfico
- Patrones sospechosos

#### 2. **Alertas** (ElastAlert)

ElastAlert detecta automáticamente:
- Actividad sospechosa en logs
- Intentos de acceso fallidos
- Cambios de privilegios

#### 3. **Casos** (TheHive)

Cuando se genera una alerta:
1. ElastAlert crea automáticamente un caso en TheHive
2. El analista revisa la información
3. Agrega observables para análisis
4. Ejecuta responders de Cortex

#### 4. **Análisis** (Cortex)

Cortex analiza automáticamente:
- IPs contra bases de datos de reputación
- Hashes contra VirusTotal
- Dominios contra registros WHOIS

#### 5. **Respuesta** (Playbooks)

Basado en resultados:
- Bloquea IPs maliciosas
- Aísla hosts comprometidos
- Escala a infraestructura

### Búsquedas Útiles en Kibana

```
# Errores HTTP
http_code >= 400

# Actividad sospechosa
message:("../") OR message:(".\\")

# Intentos de login fallidos
message:("failed" OR "denied" OR "authentication failure")

# Cambios de permisos
message:(chmod OR chown OR sudo)

# Últimas 24 horas
@timestamp:[now-24h TO now]
```

---

## 🔧 Troubleshooting

### Elasticsearch no inicia

```bash
# Verificar logs
docker-compose logs elasticsearch

# Aumentar memoria disponible
# En docker-compose.yml, aumentar ES_JAVA_OPTS

# Limpiar volúmenes (CUIDADO - borra datos)
docker-compose down -v
docker-compose up -d
```

### Kibana no se conecta a Elasticsearch

```bash
# Verificar conectividad
docker exec soc4-kibana curl -v http://elasticsearch:9200

# Verificar configuración
docker-compose logs kibana

# Reiniciar Kibana
docker-compose restart kibana
```

### ElastAlert no genera alertas

```bash
# Ver logs de ElastAlert
docker-compose logs elastalert

# Validar reglas YAML
docker exec soc4-elastalert elastalert --config /opt/elastalert/config.yaml --rule /opt/elastalert/rules --debug

# Verificar índices en Elasticsearch
curl http://localhost:9200/_cat/indices | grep logs
```

### TheHive/Cortex no se comunican

```bash
# Desde TheHive, probar conexión a Cortex
docker exec soc4-thehive curl -v http://cortex:9001/api/status

# Verificar logs de ambos
docker-compose logs thehive cortex

# Reiniciar ambos servicios
docker-compose restart thehive cortex
```

---

## 📋 Mejores Prácticas

### 1. **Backup Regular**

```bash
# Hacer backup de Elasticsearch
docker exec soc4-elasticsearch elasticdump \
  --input http://localhost:9200 \
  --output backup-$(date +%Y%m%d).json
```

### 2. **Monitoreo del Espacio Disco**

```bash
# Verificar uso de espacio
docker exec soc4-elasticsearch curl http://localhost:9200/_cat/allocation?v

# Configurar política de retención de índices
# En Kibana: Stack Management → Index Lifecycle Policies
```

### 3. **Seguridad**

- Cambiar contraseñas por defecto
- Configurar SSL/TLS
- Implementar autenticación LDAP en TheHive
- Limitar acceso por IP firewall

### 4. **Performance**

- Aumentar workers de Logstash si hay lag
- Ajustar batch size según recursos
- Usar filtros específicos en Filebeat
- Implementar políticas de índices (ILM)

### 5. **Mantenimiento**

Revisar regularmente:
- Logs de error en todos los servicios
- Espacio disponible en disco
- Cantidad de eventos procesados
- Falsos positivos en alertas

---

## 📞 Soporte y Documentación

- **Elasticsearch**: https://www.elastic.co/guide/
- **TheHive**: https://docs.thehive-project.org/
- **Cortex**: https://github.com/TheHive-Project/Cortex
- **ElastAlert**: https://elastalert.readthedocs.io/

---

## 📝 Changelog

### v1.0 (Febrero 2026)
- ✓ Configuración inicial del SOC
- ✓ Integración ELK Stack
- ✓ Integración TheHive/Cortex
- ✓ Reglas de alerta ElastAlert
- ✓ Scripts de automatización
- ✓ Guía de operación

---

**Última Actualización**: 11 de febrero de 2026
**Versión**: 1.0
**Mantenedor**: SOC Team
#   S O C  
 #   S O C  
 #   S O C  
 #   S O C  
 #   S O C  
 
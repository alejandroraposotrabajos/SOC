# Memoria Técnica — CyberSOC básico

## 1. Objetivo
Proporcionar una infraestructura desplegable por Docker que cubra el ciclo de vida de un incidente: ingestión de logs, análisis/correlación, generación de alertas y gestión de incidentes (ticketing).

## 2. Arquitectura y esquema de red
- Despliegue mediante `docker-compose.yml` en modo bridge dentro de la red `cybsoc_net` (subred 172.22.0.0/16).
- Servicios principales:
  - `elasticsearch`: almacenamiento y búsqueda de logs.
  - `logstash`: ingesta y normalización de logs.
  - `filebeat`: agente de recolección que envía a Logstash.
  - `kibana`: visualización y dashboards.
  - `thehive`: gestión de incidentes (ticketing).
  - `cortex`: análisis automatizado de artefactos.
  - `elastalert`: motor de alertas basadas en reglas.
  - `cassandra`: backend para TheHive.

Todos los servicios exponen puertos locales mapeados para su acceso (9200 ES, 5601 Kibana, 9000 TheHive, 9001 Cortex, 5000/5001 Logstash).

## 3. Justificación de herramientas
- Elastic Stack (Elasticsearch / Logstash / Kibana): sólido ecosistema para ingesta y visualización de logs.
- Filebeat: liviano y bien integrado con ELK para recolectar de endpoints y contenedores.
- TheHive + Cortex: solución open-source para gestión y enriquecimiento de incidentes.
- ElastAlert: reglas simples basadas en Elasticsearch para generación de alertas.

## 4. Flujo de datos
1. Filebeat recolecta logs de sistemas, aplicaciones y contenedores.
2. Filebeat envía mensajes a Logstash (puerto 5000/5001).
3. Logstash aplica filtros (geoip, useragent, reglas de detección) y normaliza campos.
4. Eventos relevantes se indexan en Elasticsearch (índices diarios `logs-YYYY.MM.dd`).
5. ElastAlert consulta Elasticsearch y dispara notificaciones si se cumplen reglas.
6. Logstash, al detectar `security_alert`, construye un payload y llama a TheHive para crear una alerta/caso.
7. Cortex puede ejecutarse desde TheHive para analizar artefactos (IP, hashes, dominios).

## 5. Política de retención de logs
- Índices diarios en Elasticsearch. Política sugerida:
  - Retener 30 días en discos de alta velocidad para análisis activos.
  - Mover a almacenamiento de baja frecuencia o eliminar después de 90 días.
- Para este entorno de laboratorio se mantiene configuración por defecto (sin ILM avanzado). En entornos productivos configurar ILM con rollover y políticas de 'hot-warm-cold'.

## 6. Controles y alertas implementadas (ejemplos)
- Detección de intentos de autenticación fallidos (patrones `failed password|authentication failure`).
- Detección de comandos sospechosos en peticiones web (payloads con `wget|curl|bash|nc|ncat`).
- Reglas de ElastAlert configuradas en `elastalert/rules/` (ejemplos: brute-force-detection, privilege-escalation, suspicious-web-activity).

## 7. Requisitos y despliegue
- Requisitos mínimos: Docker y Docker Compose instalados en host con suficiente memoria (>= 4GB) y ~10GB de espacio.
- Despliegue:
```powershell
cd "C:\Users\Usuario\Desktop\Codigo clase\PPS\SOC 4"
.\scripts\Start-SOC.ps1
```

## 8. Operación y mantenimiento
- Revisar estados via `docker ps` y `docker logs`.
- Renovación de tokens (TheHive/Cortex) y rotación de secretos mediante `.env`.
- Backups periódicos de indices ES y de volúmenes (elasticsearch-data, thehive-data, cortex-jobs).

## 9. Mapa de cobertura de criterios de evaluación
- Criterio b: controles y detección implementados mediante Logstash + ElastAlert + Filebeat.
- Criterio e: gestión y seguimiento de incidentes mediante TheHive + playbook y Cortex para enriquecimiento.

---

*Documento generado para la entrega del ejercicio de UD 4.*

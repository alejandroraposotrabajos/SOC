# ✅ SOC - Checklist de Verificación

## 📋 Pre-Inicio

### Requisitos del Sistema
- [ ] Docker instalado (versión 20.10+)
- [ ] Docker Compose instalado (versión 1.29+)
- [ ] Al menos 8GB de RAM disponible
- [ ] 50GB de espacio en disco disponible
- [ ] Puerto 5000, 5001, 5601, 9000, 9001, 9200, 9600 libres

### Configuración
- [ ] Archivos de configuración creados
- [ ] docker-compose.yml en lugar correcto
- [ ] Scripts de automatización ejecutables
- [ ] Variables de entorno configuradas

---

## 🚀 Durante el Inicio

### Verificación de Servicios
- [ ] Elasticsearch inicia correctamente
- [ ] Logstash conecta a Elasticsearch
- [ ] Kibana se conecta a Elasticsearch
- [ ] Filebeat envía logs a Logstash
- [ ] TheHive se conecta a Elasticsearch
- [ ] Cortex inicia sin errores
- [ ] ElastAlert conecta a Elasticsearch

### Validación de Conexiones
```bash
# Elasticsearch
curl http://localhost:9200/_cluster/health

# Logstash
curl http://localhost:9600/_node/stats

# Kibana
curl http://localhost:5601/api/status

# TheHive
curl http://localhost:9000/

# Cortex
curl http://localhost:9001/api/status
```

---

## 🔧 Configuración Post-Inicio

### Kibana Setup
- [ ] Crear patrón de índice (Index Pattern) `logs-*`
- [ ] Crear dashboards de monitoreo
- [ ] Configurar alertas
- [ ] Personalizar visualizaciones

### TheHive Setup
- [ ] Crear usuario administrativo
- [ ] Configurar API key
- [ ] Probar integración con Cortex
- [ ] Crear templates de casos (optional)

### Cortex Setup
- [ ] Configurar API key
- [ ] Habilitar analizadores necesarios
- [ ] Probar análisis en TheHive
- [ ] Configurar límites de rate

### ElastAlert Setup
- [ ] Validar reglas YAML
- [ ] Probar conexión a TheHive
- [ ] Probar envío de correos
- [ ] Ajustar umbrales de alertas

---

## 📊 Monitoreo Diario

### Cada Mañana
- [ ] Revisar logs de errores: `docker-compose logs`
- [ ] Ejecutar health check: `./scripts/Health-Check.ps1`
- [ ] Verificar espacio disco: `docker exec soc4-elasticsearch curl http://localhost:9200/_cat/allocation?v`
- [ ] Revisar alertas generadas en ElastAlert
- [ ] Chequear casos nuevos en TheHive

### Cada Semana
- [ ] Revisar performance de Elasticsearch
- [ ] Limpiar índices antiguos (>30 días)
- [ ] Hacer backup de datos críticos
- [ ] Revisar logs de falsos positivos
- [ ] Actualizar reglas de ElastAlert

### Cada Mes
- [ ] Análisis de tendencias de seguridad
- [ ] Auditoría de accesos a TheHive
- [ ] Revisión de storage utilizado
- [ ] Pruebas de recuperación de backup
- [ ] Actualización de versiones (opcional)

---

## 🚨 Troubleshooting Rápido

### Si un servicio no inicia

```bash
# Ver logs
docker-compose logs [servicio]

# Reiniciar servicio
docker-compose restart [servicio]

# Recrear desde 0
docker-compose down
docker-compose up -d
```

### Si Elasticsearch está lento

```bash
# Ver número de shards
curl http://localhost:9200/_cat/shards

# Ver tamaño de índices
curl http://localhost:9200/_cat/indices?v

# Reducir shards de índices antiguos
curl -X PUT "localhost:9200/logs-old-index/_settings" -d '{"number_of_replicas":0}'
```

### Si TheHive no conecta a Cortex

```bash
# Verificar conectividad
docker exec soc4-thehive curl -v http://cortex:9001/api/status

# Verificar API key
docker logs soc4-thehive | grep -i cortex
```

### Si ElastAlert no genera alertas

```bash
# Validar sintaxis de reglas
docker exec soc4-elastalert elastalert --config /opt/elastalert/config.yaml --debug

# Ver logs
docker logs soc4-elastalert

# Verificar índices
curl "http://localhost:9200/_cat/indices?v" | grep logs
```

---

## 🔐 Chequeo de Seguridad

### Acceso y Autenticación
- [ ] Cambiar contraseña de elastic (Elasticsearch)
- [ ] Crear usuario admin en TheHive
- [ ] Habilitar LDAP (si aplica)
- [ ] Configurar firewall para limitar acceso
- [ ] Cambiar claves de sesión predefinidas

### Encriptación
- [ ] Habilitar SSL/TLS en Elasticsearch
- [ ] Configurar HTTPS en Kibana
- [ ] Certificados válidos instalados
- [ ] Conexiones internas encriptadas

### Auditoría
- [ ] Logging habilitado en todos los servicios
- [ ] Logs enviados a ubicación centralizada
- [ ] Retención de logs configurada
- [ ] Acceso a logs restringido

---

## 📈 Optimización

### Performance
- [ ] Elasticsearch: workers y batch size optimizados
- [ ] Logstash: pipelines ajustados
- [ ] Filebeat: múltiples workers configurados
- [ ] Memoria RAM asignada correctamente
- [ ] Disco con IOPS suficiente

### Almacenamiento
- [ ] Política ILM configurada
- [ ] Rotación de índices automática
- [ ] Compresión habilitada
- [ ] Snapshots configurados
- [ ] Limite de retención establecido

### Escalabilidad
- [ ] Múltiples nodes de Elasticsearch (si aplica)
- [ ] Load balancing configurado (si aplica)
- [ ] Sharding ajustado al volumen
- [ ] Réplicas configuradas

---

## 🧪 Testing

### Test de Recolección de Logs
```bash
# Enviar log de prueba a Logstash
echo '{"test": "mensaje"}' | nc -u localhost 5001

# Verificar en Elasticsearch
curl "http://localhost:9200/logs-*/_search?q=test" | jq
```

### Test de Alertas
```bash
# Crear evento que dispare alerta en Kibana
# O modificar threshold de una regla ElastAlert a nivel bajo
```

### Test de Integración TheHive-Cortex
1. Ir a TheHive
2. Crear caso de prueba
3. Agregar observable (IP, hash, etc.)
4. Ejecutar responder de Cortex
5. Verificar resultados

---

## 📝 Documentación

### Archivos Incluidos
- [ ] README.md - Guía operacional
- [ ] ADVANCED.md - Configuración avanzada
- [ ] INSTALLATION_SUMMARY.md - Resumen de cambios
- [ ] Este archivo - Checklist

### Recursos Externos
- [ ] Documentación Elasticsearch: https://www.elastic.co/guide/
- [ ] TheHive Project: https://docs.thehive-project.org/
- [ ] Cortex: https://github.com/TheHive-Project/Cortex
- [ ] ElastAlert2: https://elastalert.readthedocs.io/

---

## 🎯 KPIs a Monitorear

Crear dashboards en Kibana para:
- [ ] Eventos procesados por hora
- [ ] Tasa de errores
- [ ] Latencia de procesamiento
- [ ] Espacio utilizado en Elasticsearch
- [ ] Número de alertas generadas
- [ ] Casos creados en TheHive
- [ ] Análisis completados en Cortex
- [ ] Uptime de servicios

---

## 📞 Contacto y Soporte

### En caso de problemas:
1. Revisar README.md
2. Revisar ADVANCED.md
3. Ejecutar Health-Check.ps1
4. Revisar logs con `docker-compose logs`
5. Consultar documentación oficial

### Información de Servicios:
- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601
- **TheHive**: http://localhost:9000
- **Cortex**: http://localhost:9001
- **Logstash**: http://localhost:9600

---

## ✅ Estado de Implementación

| Componente | Estado | Verificado |
|-----------|--------|-----------|
| Docker Compose | ✅ Completo | [ ] |
| Elasticsearch | ✅ Completo | [ ] |
| Logstash | ✅ Completo | [ ] |
| Kibana | ✅ Completo | [ ] |
| Filebeat | ✅ Completo | [ ] |
| TheHive | ✅ Completo | [ ] |
| Cortex | ✅ Completo | [ ] |
| ElastAlert | ✅ Completo | [ ] |
| Scripts Bash | ✅ Completo | [ ] |
| Scripts PowerShell | ✅ Completo | [ ] |
| Documentación | ✅ Completo | [ ] |
| Reglas de Alerta | ✅ 4 reglas | [ ] |

---

**Última Actualización**: 11 de febrero de 2026
**Próxima Revisión**: 18 de febrero de 2026
**Responsable**: SOC Team

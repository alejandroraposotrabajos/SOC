# Playbook (Manual de Operación) — Analista SOC Nivel 1

Este playbook describe los pasos a seguir cuando salta una alerta crítica generada por el SOC.

## Escenario de ejemplo: Alerta de intento de autenticación fallido (brute-force)

1. Detección
   - Fuente: ElastAlert o Logstash (evento con `auth_failure` tag).
   - Prioridad: Alta/Media según número de eventos.

2. Triage inicial
   - Abrir la alerta en TheHive (si no se creó automáticamente).
   - Revisar la descripción y los artefactos (IP, hostname, usuario implicado).
   - Validar la temporalidad: ¿fue hoy? ¿duró X minutos?

3. Enriquecimiento
   - Ejecutar analyzers de Cortex sobre la IP (GeoIP, Whois, AbuseIPDB) y sobre el hostname.
   - Consultar registros en Kibana: buscar en los índices `logs-*` por la IP/usuario y la hora del evento.

4. Clasificación
   - Si es falso positivo (p.ej. actividad de escaneo interno autorizado) marcar como `False Positive`.
   - Si es actividad maliciosa: clasificar según impacto (Low/Medium/High).

5. Contención (si aplica)
   - Bloquear IP en firewall o en el equipo afectado (seguir procedimientos de la organización).
   - Forzar cambio de credenciales si hubo compromiso.

6. Escalado
   - Si el incidente requiere, escalar a Nivel 2 y notificar al equipo de respuesta.
   - Adjuntar en TheHive todas las evidencias: logs, capturas, analíticas.

7. Resolución y cierre
   - Registrar las acciones tomadas, tiempos y evidencias en TheHive.
   - Cerrar el caso solo después de verificar la mitigación y su efectividad.

8. Lessons Learned
   - Tras el cierre, redactar un breve informe con la causa raíz y medidas preventivas.


## Comandos y consultas útiles
- Buscar eventos en Kibana por IP:
  - `client.ip: 1.2.3.4`
- Ejecutar analyzer en Cortex desde TheHive (UI -> Analyzers -> run)

## Roles y responsabilidades
- Analista Nivel 1: triage, enriquecimiento inicial, contención básica.
- Analista Nivel 2: análisis forense, corrección de vulnerabilidades, coordinación de respuesta.

---
*Playbook mínimo para la práctica y evaluación.*

# Guía de Demostración — Caso práctico

Objetivo: ejecutar un ataque simulado (fuerza bruta SSH o intento de login) y demostrar el flujo: detección → alerta → creación de caso en TheHive.

## Preparación
1. Arrancar el SOC:
```powershell
cd "C:\Users\Usuario\Desktop\Codigo clase\PPS\SOC 4"
.\scripts\Start-SOC.ps1
```
2. Asegurarse de que `THEHIVE_API_KEY` esté en `.env` y que los contenedores estén levantados.

## Ejecutar ataque simulado (PowerShell)
- Script preparado: `scripts/simulate-ssh-bruteforce.ps1`.
- Ejecución:
```powershell
cd "C:\Users\Usuario\Desktop\Codigo clase\PPS\SOC 4"
# Enviar 50 eventos de intento fallido hacia Logstash
.\scripts\simulate-ssh-bruteforce.ps1 -Host 127.0.0.1 -Port 5001 -Count 50 -DelayMs 100
```

## Observación en tiempo real
- Ver logs de Logstash (ver que recibe y procesa eventos):
```powershell
docker logs -f soc4-logstash
```
- Verifique que se indexan eventos en Elasticsearch y que Kibana muestra los logs (usar Discover).
- Ver TheHive: ver si se creó una alerta/caso automático a partir del payload enviado por Logstash.

## Validación
- En TheHive debería aparecer un nuevo caso con título `Alerta SOC: ...` y artifacts.
- En Cortex (desde TheHive) lanzar analyzers sobre la IP para enriquecer la evidencia.

## Alternativa: Simular tráfico web sospechoso (Linux/bash)
```bash
# Enviar mensajes al puerto UDP 5000
for i in {1..40}; do echo "GET /index.php?cmd=whoami HTTP/1.1" | nc -u 127.0.0.1 5000; sleep 0.1; done
```

---
*Fin de la guía de demostración.*

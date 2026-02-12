#!/bin/bash
# Envia una serie de peticiones simuladas con payloads sospechosos al puerto UDP de Logstash (5000)
HOST=${1:-127.0.0.1}
PORT=${2:-5000}
COUNT=${3:-40}
DELAY=${4:-0.1}

for i in $(seq 1 $COUNT); do
  echo "GET /index.php?cmd=whoami HTTP/1.1\r\nHost: vulnerable.local\r\nUser-Agent: curl/7.$i\r\n\r\n" | nc -u $HOST $PORT
  sleep $DELAY
done

echo "Envío completado: $COUNT mensajes a $HOST:$PORT"
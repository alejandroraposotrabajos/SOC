#!/bin/bash
# ==============================================================================
# Script: start-soc.sh
# Descripción: Inicia el SOC completo con validaciones
# Uso: ./start-soc.sh
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/soc_startup.log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================= Funciones de Logging =================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓ OK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠️  WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ================= Verificaciones Previas =================
check_prerequisites() {
    log_info "Verificando requisitos previos..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado"
        exit 1
    fi
    log_success "Docker está instalado"
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose no está instalado"
        exit 1
    fi
    log_success "Docker Compose está instalado"
    
    # Verificar que Docker daemon está corriendo
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon no está corriendo"
        exit 1
    fi
    log_success "Docker daemon está activo"
}

# ================= Validación de Configuraciones =================
validate_configs() {
    log_info "Validando archivos de configuración..."
    
    local configs=(
        "$PROJECT_DIR/docker-compose.yml"
        "$PROJECT_DIR/agents/filebeat/filebeat.yml"
        "$PROJECT_DIR/ELK/logstash/pipeline/logstash.conf"
        "$PROJECT_DIR/elastalert/config.yaml"
        "$PROJECT_DIR/cortex/config/application.conf"
        "$PROJECT_DIR/thehive/config/application.conf"
    )
    
    for config in "${configs[@]}"; do
        if [ ! -f "$config" ]; then
            log_error "Archivo de configuración no encontrado: $config"
            exit 1
        fi
        log_success "Configuración encontrada: $(basename $config)"
    done
}

# ================= Limpieza de Estado Anterior =================
cleanup_previous_state() {
    log_info "Limpiando estado anterior..."
    
    # Remover contenedores previos si existen
    docker-compose -f "$PROJECT_DIR/docker-compose.yml" down --remove-orphans 2>/dev/null || true
    log_success "Contenedores anteriores removidos"
}

# ================= Iniciar Servicios =================
start_services() {
    log_info "Iniciando servicios SOC..."
    
    cd "$PROJECT_DIR"
    docker-compose up -d
    
    log_success "Docker Compose iniciado"
}

# ================= Esperar a que los Servicios Estén Listos =================
wait_for_services() {
    log_info "Esperando a que los servicios se estabilicen..."
    
    local max_attempts=30
    local attempt=1
    
    # Esperar a Elasticsearch
    log_info "Esperando a Elasticsearch..."
    while [ $attempt -le $max_attempts ]; do
        if docker exec soc4-elasticsearch curl -s http://localhost:9200/_cluster/health | grep -q '"status":"yellow"\|"status":"green"'; then
            log_success "Elasticsearch está listo"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            log_error "Elasticsearch no respondió en tiempo"
            exit 1
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Esperar a Kibana
    log_info "Esperando a Kibana..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec soc4-kibana curl -s http://localhost:5601/api/status | grep -q 'state'; then
            log_success "Kibana está listo"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            log_error "Kibana no respondió en tiempo"
            exit 1
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Esperar a TheHive
    log_info "Esperando a TheHive..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec soc4-thehive curl -s http://localhost:9000/ | grep -q 'TheHive'; then
            log_success "TheHive está listo"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            log_error "TheHive no respondió en tiempo"
            exit 1
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Esperar a Cortex
    log_info "Esperando a Cortex..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker exec soc4-cortex curl -s http://localhost:9001/api/status | grep -q 'status'; then
            log_success "Cortex está listo"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            log_error "Cortex no respondió en tiempo"
            exit 1
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    sleep 5
    log_success "Todos los servicios están listos"
}

# ================= Mostrar Estado Final =================
show_summary() {
    log_success "SOC iniciado exitosamente"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}SOC COMPLETAMENTE OPERATIVO${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Servicios Disponibles:${NC}"
    echo "  📊 Kibana:     http://localhost:5601"
    echo "  🔍 Elasticsearch: http://localhost:9200"
    echo "  🛡️  TheHive:    http://localhost:9000"
    echo "  🔬 Cortex:     http://localhost:9001"
    echo "  📡 Logstash:   http://localhost:9600"
    echo ""
    echo -e "${YELLOW}Puertos Disponibles:${NC}"
    echo "  📥 Logstash Beats: 5000 (TCP/UDP)"
    echo "  📥 Logstash TCP:   5001 (TCP)"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

# ================= Función Principal =================
main() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          SOC - Security Operations Center${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    check_prerequisites
    echo ""
    validate_configs
    echo ""
    cleanup_previous_state
    echo ""
    start_services
    echo ""
    wait_for_services
    echo ""
    show_summary
}

# Ejecutar
main

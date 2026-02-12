#!/bin/bash
# ==============================================================================
# Script: stop-soc.sh
# Descripción: Detiene el SOC de forma controlada
# Uso: ./stop-soc.sh
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/../soc_shutdown.log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

main() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}              DETENIENDO SOC${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    cd "$PROJECT_DIR/.."
    
    log_info "Guardando logs y snapshots..."
    docker-compose logs > soc_logs_backup_$(date +%Y%m%d_%H%M%S).log 2>&1 || true
    
    log_info "Deteniendo servicios..."
    docker-compose down
    
    log_success "SOC detenido correctamente"
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

main

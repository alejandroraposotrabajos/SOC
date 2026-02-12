# ==============================================================================
# Script: Start-SOC.ps1
# Descripción: Inicia el SOC completo con validaciones (PowerShell)
# Uso: .\Start-SOC.ps1
# ==============================================================================

param(
    [switch]$NoWait = $false,
    [int]$TimeoutMinutes = 5
)

$ErrorActionPreference = "Stop"

# Definir directorio del proyecto
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $projectDir
$logFile = Join-Path $projectDir "soc_startup.log"

# Funciones de logging
function Write-LogInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = "[INFO] $timestamp - $Message"
    Write-Host $output -ForegroundColor Cyan
    Add-Content -Path $logFile -Value $output
}

function Write-LogSuccess {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = "[OK] $timestamp - $Message"
    Write-Host $output -ForegroundColor Green
    Add-Content -Path $logFile -Value $output
}

function Write-LogError {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = "[ERROR] $timestamp - $Message"
    Write-Host $output -ForegroundColor Red
    Add-Content -Path $logFile -Value $output
}

function Write-LogWarning {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $output = "[WARNING] $timestamp - $Message"
    Write-Host $output -ForegroundColor Yellow
    Add-Content -Path $logFile -Value $output
}

# Verificar requisitos
function Check-Prerequisites {
    Write-LogInfo "Verificando requisitos previos..."
    
    # Verificar Docker
    try {
        docker --version > $null
        Write-LogSuccess "Docker está instalado"
    } catch {
        Write-LogError "Docker no está instalado"
        exit 1
    }
    
    # Verificar Docker Compose
    try {
        docker-compose --version > $null
        Write-LogSuccess "Docker Compose está instalado"
    } catch {
        Write-LogError "Docker Compose no está instalado"
        exit 1
    }
    
    # Verificar Docker daemon
    try {
        docker info > $null
        Write-LogSuccess "Docker daemon está activo"
    } catch {
        Write-LogError "Docker daemon no está corriendo"
        exit 1
    }
}

# Validar configuraciones
function Validate-Configs {
    Write-LogInfo "Validando archivos de configuración..."
    
    $configs = @(
        "docker-compose.yml",
        "agents\filebeat\filebeat.yml",
        "ELK\logstash\pipeline\logstash.conf",
        "elastalert\config.yaml",
        "cortex\config\application.conf",
        "thehive\config\application.conf"
    )
    
    foreach ($config in $configs) {
        $path = Join-Path $projectDir $config
        if (Test-Path $path) {
            Write-LogSuccess "Configuración encontrada: $(Split-Path -Leaf $path)"
        } else {
            Write-LogError "Archivo no encontrado: $config"
            exit 1
        }
    }

    # Comprobar archivo .env para secretos (opcional pero recomendado)
    $envFile = Join-Path $projectDir ".env"
    if (Test-Path $envFile) {
        Write-LogSuccess ".env encontrado"
        try {
            $envContent = Get-Content $envFile -ErrorAction Stop
            $theKeyLine = $envContent | Where-Object { $_ -match '^THEHIVE_API_KEY=' }
            if ($theKeyLine) {
                if ($theKeyLine -match 'changeme_replace_with_real_token') {
                    Write-LogWarning "THEHIVE_API_KEY en .env contiene el placeholder. Reemplázalo por el token real de TheHive."
                } else {
                    Write-LogSuccess "THEHIVE_API_KEY presente en .env"
                }
            } else {
                Write-LogWarning "THEHIVE_API_KEY no encontrada en .env. Añádela para que Logstash pueda autenticar con TheHive si es necesario."
            }
        } catch {
            Write-LogWarning "No se pudo leer .env: $($_.Exception.Message)"
        }
    } else {
        Write-LogWarning ".env no encontrado. Puedes crear uno a partir de .env.example con THEHIVE_API_KEY."
    }
}

# Limpiar estado anterior
function Cleanup-Previous {
    Write-LogInfo "Limpiando estado anterior..."
    
    Push-Location $projectDir
    try {
        docker-compose down --remove-orphans 2>$null
        Write-LogSuccess "Contenedores anteriores removidos"
    } finally {
        Pop-Location
    }
}

# Iniciar servicios
function Start-Services {
    Write-LogInfo "Iniciando servicios SOC..."
    
    Push-Location $projectDir
    try {
        docker-compose up -d
        Write-LogSuccess "Docker Compose iniciado"
    } finally {
        Pop-Location
    }
}

# Esperar a que los servicios estén listos
function Wait-ForServices {
    Write-LogInfo "Esperando a que los servicios se estabilicen..."
    
    $timeout = [DateTime]::Now.AddMinutes($TimeoutMinutes)
    
    # Esperar a Elasticsearch
    Write-LogInfo "Esperando a Elasticsearch..."
    while ([DateTime]::Now -lt $timeout) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "Elasticsearch está listo"
                break
            }
        } catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 2
        }
    }
    
    # Esperar a Kibana
    Write-LogInfo "Esperando a Kibana..."
    $timeout = [DateTime]::Now.AddMinutes($TimeoutMinutes)
    while ([DateTime]::Now -lt $timeout) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5601/api/status" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "Kibana está listo"
                break
            }
        } catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 2
        }
    }
    
    # Esperar a TheHive
    Write-LogInfo "Esperando a TheHive..."
    $timeout = [DateTime]::Now.AddMinutes($TimeoutMinutes)
    while ([DateTime]::Now -lt $timeout) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9000/" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "TheHive está listo"
                break
            }
        } catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 2
        }
    }
    
    # Esperar a Cortex
    Write-LogInfo "Esperando a Cortex..."
    $timeout = [DateTime]::Now.AddMinutes($TimeoutMinutes)
    while ([DateTime]::Now -lt $timeout) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9001/api/status" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-LogSuccess "Cortex está listo"
                break
            }
        } catch {
            Write-Host -NoNewline "."
            Start-Sleep -Seconds 2
        }
    }
    
    Start-Sleep -Seconds 5
    Write-LogSuccess "Todos los servicios están listos"
}

# Mostrar resumen
function Show-Summary {
    Write-LogSuccess "SOC iniciado exitosamente"
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "SOC COMPLETAMENTE OPERATIVO" -ForegroundColor Green
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Servicios Disponibles:" -ForegroundColor Yellow
    Write-Host "  Kibana:        http://localhost:5601"
    Write-Host "  Elasticsearch: http://localhost:9200"
    Write-Host "  TheHive:       http://localhost:9000"
    Write-Host "  Cortex:        http://localhost:9001"
    Write-Host "  Logstash:      http://localhost:9600"
    Write-Host ""
    Write-Host "Puertos Disponibles:" -ForegroundColor Yellow
    Write-Host "  Logstash Beats: 5000 (TCP/UDP)"
    Write-Host "  Logstash TCP:   5001 (TCP)"
    Write-Host ""
    Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
}

# Función principal
function Main {
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "SOC - Security Operations Center" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Crear archivo de log
    New-Item -Path $logFile -Force > $null
    
    Check-Prerequisites
    Write-Host ""
    Validate-Configs
    Write-Host ""
    Cleanup-Previous
    Write-Host ""
    Start-Services
    Write-Host ""
    
    if (-not $NoWait) {
        Wait-ForServices
        Write-Host ""
        Show-Summary
    }
}

# Ejecutar
Main

# ==============================================================================
# Script: Stop-SOC.ps1
# Descripción: Detiene el SOC de forma controlada (PowerShell)
# Uso: .\Stop-SOC.ps1
# ==============================================================================

param(
    [switch]$SaveLogs = $true
)

$ErrorActionPreference = "Continue"

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $projectDir
$logFile = Join-Path $projectDir "soc_shutdown.log"

function Write-LogInfo {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[INFO] $timestamp - $Message" -ForegroundColor Cyan
    Add-Content -Path $logFile -Value "[INFO] $timestamp - $Message"
}

function Write-LogSuccess {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[✓] $timestamp - $Message" -ForegroundColor Green
    Add-Content -Path $logFile -Value "[✓] $timestamp - $Message"
}

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DETENIENDO SOC" -ForegroundColor Red
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

New-Item -Path $logFile -Force > $null

Push-Location $projectDir

try {
    if ($SaveLogs) {
        Write-LogInfo "Guardando logs..."
        $backupName = "soc_logs_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        docker-compose logs > $backupName 2>&1
        Write-LogSuccess "Logs guardados en: $backupName"
    }
    
    Write-LogInfo "Deteniendo servicios..."
    docker-compose down
    
    Write-LogSuccess "SOC detenido correctamente"
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
} finally {
    Pop-Location
}

<#
.SYNOPSIS
  Simula múltiples intentos de login fallidos enviando mensajes al endpoint de Logstash.

.PARAMETER Host
  Host donde está escuchando Logstash (por defecto 127.0.0.1)

.PARAMETER Port
  Puerto TCP de Logstash (por defecto 5001)

.PARAMETER Count
  Número de mensajes a enviar (por defecto 20)

.PARAMETER DelayMs
  Retraso en ms entre mensajes (por defecto 200)

.EXAMPLE
  .\simulate-ssh-bruteforce.ps1 -Host 127.0.0.1 -Port 5001 -Count 50 -DelayMs 50
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [ValidateNotNullOrEmpty()]
  [string]$TargetHost = '127.0.0.1',

  [Parameter(Mandatory=$false)]
  [ValidateRange(1,65535)]
  [int]$TargetPort = 5001,

  [Parameter(Mandatory=$false)]
  [ValidateRange(1,1000000)]
  [int]$Count = 20,

  [Parameter(Mandatory=$false)]
  [ValidateRange(0,60000)]
  [int]$DelayMs = 200
)

Write-Host "Enviando $Count intentos fallidos a ${TargetHost}:${TargetPort}" -ForegroundColor Cyan
for ($i=1; $i -le $Count; $i++) {
  $client = $null
  $writer = $null
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($TargetHost, $TargetPort)
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::UTF8)
    $writer.AutoFlush = $true

    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $message = "$timestamp host=targethost sshd[12345]: Failed password for invalid user testuser from 10.0.0.$i port 22 ssh2"

    $writer.WriteLine($message)
    Write-Host "[$i] Sent: $message" -ForegroundColor Green
  } catch {
    Write-Warning "[$i] Fallo al enviar: $($_.Exception.Message)"
  } finally {
    try { if ($writer) { $writer.Close() } } catch {}
    try { if ($stream) { $stream.Dispose() } } catch {}
    try { if ($client) { $client.Close() } } catch {}
  }

  Start-Sleep -Milliseconds $DelayMs
}

Write-Host "Envio completado." -ForegroundColor Yellow

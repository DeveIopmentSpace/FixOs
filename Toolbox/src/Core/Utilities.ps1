function Test-InternetConnection {
    try {
        $test = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
        return $test
    } catch {
        return $false
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path "Toolbox.log" -Value $logEntry
    
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        default { Write-Host $logEntry -ForegroundColor White }
    }
}

function Show-Countdown {
    param([int]$Seconds = 3)
    
    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host (Center-Text "Continuing in $i...") -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        Write-Host "`r" -NoNewline
    }
    Write-Host ""
}
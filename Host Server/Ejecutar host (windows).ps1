$pythonExists = (Get-Command py -ErrorAction SilentlyContinue) -or (Get-Command python -ErrorAction SilentlyContinue)

if (-not $pythonExists) {
    Write-Host "Python no está instalado. Instalando Python..." -ForegroundColor Yellow

    winget install --id Python.Python.3 --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: No se pudo instalar Python." -ForegroundColor Red
        exit 1
    }

    # Actualizar el PATH de esta sesión
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Comprobar nuevamente si Python está disponible
    $pythonExists = (Get-Command py -ErrorAction SilentlyContinue) -or
                    (Get-Command python -ErrorAction SilentlyContinue)

    if (-not $pythonExists) {
        Write-Host "ERROR: Python se instaló, pero no se encontró en el PATH." -ForegroundColor Red
        Write-Host "Cierra y vuelve a abrir PowerShell e inténtalo nuevamente." -ForegroundColor Yellow
        exit 1
    }
}

# Ejecutar host.py
if (Get-Command py -ErrorAction SilentlyContinue) {
    Write-Host "Ejecutando host.py..." -ForegroundColor Green
    py host.py
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "Ejecutando host.py..." -ForegroundColor Green
    python host.py
} else {
    Write-Host "ERROR: No se encontró Python." -ForegroundColor Red
    exit 1
}
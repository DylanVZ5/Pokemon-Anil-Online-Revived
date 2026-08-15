$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        Iniciando host.py" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Buscar Python real
$pythonCommand = $null

if (Get-Command py -ErrorAction SilentlyContinue) {
    py --version 2>$null

    if ($LASTEXITCODE -eq 0) {
        $pythonCommand = "py"
    }
}

if (-not $pythonCommand) {
    $pythonExe = Get-Command python.exe -ErrorAction SilentlyContinue

    if ($pythonExe -and $pythonExe.Source -notlike "*WindowsApps*") {
        python --version 2>$null

        if ($LASTEXITCODE -eq 0) {
            $pythonCommand = "python"
        }
    }
}

# Si Python no existe, instalar la ultima version disponible
if (-not $pythonCommand) {

    Write-Host "Python is not installed." -ForegroundColor Yellow
    Write-Host "Searching for the latest Python version..." -ForegroundColor Yellow
    Write-Host ""

    $searchResult = winget search --name Python --source winget --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Could not search for Python in WinGet." -ForegroundColor Red
        Read-Host "Press ENTER to close"
        exit 1
    }

    # Buscar paquetes oficiales Python.Python.3.x
    $pythonPackages = @()

    foreach ($line in $searchResult) {

        if ($line -match "Python\s+3\.\d+\s+Python\.Python\.3\.(\d+)\s+([\d\.]+)") {

            $minorVersion = $Matches[1]
            $versionText = $Matches[2]

            try {
                $version = [System.Version]$versionText

                $pythonPackages += [PSCustomObject]@{
                    Id      = "Python.Python.3.$minorVersion"
                    Version = $version
                }
            }
            catch {
            }
        }
    }

    if ($pythonPackages.Count -eq 0) {
        Write-Host ""
        Write-Host "ERROR: No compatible Python package was found in WinGet." -ForegroundColor Red
        Read-Host "Press ENTER to close"
        exit 1
    }

    # Seleccionar la version mas nueva
    $latestPython = $pythonPackages |
        Sort-Object Version -Descending |
        Select-Object -First 1

    Write-Host "Latest Python found:" -ForegroundColor Green
    Write-Host "$($latestPython.Id) - $($latestPython.Version)" -ForegroundColor Green
    Write-Host ""

    Write-Host "Installing Python..." -ForegroundColor Yellow
    Write-Host ""

    winget install `
        --id $latestPython.Id `
        --source winget `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Python installation failed." -ForegroundColor Red
        Write-Host "Winget error code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host ""
        Read-Host "Press ENTER to close"
        exit 1
    }

    Write-Host ""
    Write-Host "Python installed successfully." -ForegroundColor Green

    # Actualizar PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    # Buscar Python nuevamente
    if (Get-Command py -ErrorAction SilentlyContinue) {
        py --version 2>$null

        if ($LASTEXITCODE -eq 0) {
            $pythonCommand = "py"
        }
    }

    if (-not $pythonCommand) {
        $pythonExe = Get-Command python.exe -ErrorAction SilentlyContinue

        if ($pythonExe -and $pythonExe.Source -notlike "*WindowsApps*") {
            python --version 2>$null

            if ($LASTEXITCODE -eq 0) {
                $pythonCommand = "python"
            }
        }
    }

    if (-not $pythonCommand) {
        Write-Host ""
        Write-Host "ERROR: Python was installed but could not be found." -ForegroundColor Red
        Write-Host "Restart PowerShell and run the script again." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press ENTER to close"
        exit 1
    }
}

# Comprobar host.py
if (-not (Test-Path ".\host.py")) {
    Write-Host ""
    Write-Host "ERROR: host.py was not found." -ForegroundColor Red
    Write-Host "Make sure host.py is in the same folder as this script." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press ENTER to close"
    exit 1
}

# Ejecutar host.py
Write-Host "Python found." -ForegroundColor Green
Write-Host "Running host.py..." -ForegroundColor Green
Write-Host ""

if ($pythonCommand -eq "py") {
    py host.py
}
else {
    python host.py
}

$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "host.py finished with code: $exitCode" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press ENTER to close"
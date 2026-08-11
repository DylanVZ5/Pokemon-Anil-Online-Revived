$pythonExists = (Get-Command py -ErrorAction SilentlyContinue) -or (Get-Command python -ErrorAction SilentlyContinue)

if (-not $pythonExists) {
    winget install --id Python.Python.3 --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    py host.py
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    python host.py
}
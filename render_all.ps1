# render_all.ps1
# Render every src/*.scad file to an STL in the publication/ folder.
# Existing STLs of the same name are overwritten.
#
# Usage:  powershell -ExecutionPolicy Bypass -File render_all.ps1

$ErrorActionPreference = 'Stop'

$root    = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir  = Join-Path $root 'src'
$outDir  = Join-Path $root 'publication'

# Locate the OpenSCAD executable.
$candidates = @(
    'C:\Program Files\OpenSCAD\openscad.exe',
    'C:\Program Files\OpenSCAD (Nightly)\openscad.exe'
)
$openscad = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $openscad) {
    $openscad = (Get-Command openscad -ErrorAction SilentlyContinue).Source
}
if (-not $openscad) {
    Write-Error 'OpenSCAD executable not found. Install it or add it to PATH.'
}

# Ensure the output folder exists.
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$scadFiles = Get-ChildItem -Path $srcDir -Filter '*.scad' | Sort-Object Name
if ($scadFiles.Count -eq 0) {
    Write-Warning "No .scad files found in $srcDir"
    return
}

$failed = 0
foreach ($scad in $scadFiles) {
    $stl = Join-Path $outDir ($scad.BaseName + '.stl')
    Write-Host "Rendering $($scad.Name) -> publication\$($scad.BaseName).stl"

    $errFile = [System.IO.Path]::GetTempFileName()
    $proc = Start-Process -FilePath $openscad `
        -ArgumentList @('-o', $stl, $scad.FullName) `
        -NoNewWindow -Wait -PassThru -RedirectStandardError $errFile

    if ($proc.ExitCode -ne 0) {
        $failed++
        Write-Host "  FAILED (exit $($proc.ExitCode))" -ForegroundColor Red
        Get-Content $errFile | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    } else {
        Write-Host "  OK" -ForegroundColor Green
    }
    Remove-Item $errFile -ErrorAction SilentlyContinue
}

Write-Host ''
if ($failed -gt 0) {
    Write-Host "$failed of $($scadFiles.Count) file(s) failed to render." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All $($scadFiles.Count) file(s) rendered to publication\." -ForegroundColor Green
}

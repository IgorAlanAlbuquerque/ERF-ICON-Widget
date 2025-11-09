#Requires -Version 5.1
param(
  [string]$PythonExe = "python",
  [string]$SwfmillExe = "swfmill",
  [switch]$SkipValidate
)

$ErrorActionPreference = "Stop"

# Raiz do repo
$ROOT = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$DIST = Join-Path $ROOT "dist"
$SCRIPT_GEN = Join-Path $ROOT "scripts/generate_xml.py"
$SCRIPT_VAL = Join-Path $ROOT "tools/validate_registry.py"
$OUT_XML    = Join-Path $DIST "ERF_UI.generated.xml"
$OUT_SWF    = Join-Path $DIST "ERF_UI.swf"

Write-Host "== ERF-UI Build =="

# Checagem Python
try {
  & $PythonExe --version | Out-Null
} catch {
  Write-Error "Python não encontrado. Passe -PythonExe ou instale o Python no PATH."
}

# Checagem swfmill
try {
  & $SwfmillExe -v | Out-Null
} catch {
  Write-Error "swfmill não encontrado. Passe -SwfmillExe ou instale via choco (choco install swfmill) e garanta que está no PATH."
}

# Validação (pode pular com -SkipValidate)
if (-not $SkipValidate) {
  Write-Host ">> Validando registry..."
  & $PythonExe $SCRIPT_VAL
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Validação falhou. Corrija os erros no registry."
  }
}

# Gerar XML
Write-Host ">> Gerando XML..."
& $PythonExe $SCRIPT_GEN
if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao gerar XML."
}

# Compilar SWF
New-Item -ItemType Directory -Force -Path $DIST | Out-Null
Write-Host ">> swfmill simple $OUT_XML -> $OUT_SWF"
& $SwfmillExe simple $OUT_XML $OUT_SWF
if ($LASTEXITCODE -ne 0) {
  Write-Error "Falha ao compilar SWF com swfmill."
}

Write-Host "OK! Artefato em: $OUT_SWF"

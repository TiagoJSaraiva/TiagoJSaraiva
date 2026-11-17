# Gera o PDF do currículo a partir do CV.md (versão para Windows / PowerShell).
#
# Uso (no PowerShell, dentro da pasta do CV):
#   .\gerar-pdf.ps1                        (CV.md -> CV.pdf)
#   .\gerar-pdf.ps1 outro.md saida.pdf
#   .\gerar-pdf.ps1 -Tex                   (também salva o .tex intermediário, para depurar)
#
# Se o Windows bloquear a execução de scripts, rode assim:
#   powershell -ExecutionPolicy Bypass -File .\gerar-pdf.ps1
#
# Requisitos (instale uma vez, no PowerShell ou no Terminal):
#   winget install --id JohnMacFarlane.Pandoc
#   winget install --id MiKTeX.MiKTeX
# Depois feche e abra o terminal de novo (para o PATH ser atualizado) e rode, uma vez:
#   initexmf --set-config-value=[MPM]AutoInstall=1
# Isso faz o MiKTeX baixar sozinho os pacotes LaTeX que faltarem na primeira geração do PDF
# (a primeira vez demora um pouco mais por causa disso).
#
# Opcional: rsvg-convert, só se você editar/adicionar ícones em icons\ (o script recria o .pdf
# de cada .svg alterado). Sem ele, os ícones PDF que já vêm na pasta continuam funcionando.

param(
    [string]$Entrada = "CV.md",
    [string]$Saida = "",
    [switch]$Tex
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if (-not $Saida) { $Saida = [System.IO.Path]::ChangeExtension($Entrada, ".pdf") }

foreach ($cmd in @("pandoc", "pdflatex")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "'$cmd' não encontrado. Veja os requisitos no topo deste script."
        exit 1
    }
}
if (-not (Test-Path $Entrada)) {
    Write-Error "Arquivo '$Entrada' não encontrado."
    exit 1
}

# Atualiza os ícones PDF a partir dos SVG (só os que mudaram)
$rsvg = Get-Command "rsvg-convert" -ErrorAction SilentlyContinue
foreach ($svg in Get-ChildItem -Path "icons" -Filter "*.svg") {
    $pdf = [System.IO.Path]::ChangeExtension($svg.FullName, ".pdf")
    if (-not (Test-Path $pdf) -or $svg.LastWriteTime -gt (Get-Item $pdf).LastWriteTime) {
        if ($rsvg) {
            & rsvg-convert -f pdf -o $pdf $svg.FullName
        } else {
            Write-Warning "$($svg.Name) mudou, mas rsvg-convert não está instalado; o ícone antigo será usado."
        }
    }
}

$opcoes = @(
    $Entrada,
    "--from=markdown",
    "--metadata-file=estilo.yaml",
    "--lua-filter=cv.lua",
    "--resource-path=.",
    "--pdf-engine=pdflatex"
)

if ($Tex) {
    $arquivoTex = [System.IO.Path]::ChangeExtension($Saida, ".tex")
    & pandoc @opcoes --standalone -o $arquivoTex
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "LaTeX salvo em $arquivoTex"
}

& pandoc @opcoes -o $Saida
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "PDF gerado: $Saida"

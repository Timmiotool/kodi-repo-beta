# Gibt die Beta-Version eines Addons als Release frei:
#   kopiert die neueste ZIP aus kodi-repo-beta\<id>\ nach kodi-repo\<id>\,
#   loescht dort aeltere ZIPs und erzeugt beide addons.xml / .md5 neu.
# Aufruf:  .\beta_freigeben.ps1            (skin.lumen)
#          .\beta_freigeben.ps1 -Addon script.library.info
param([string]$Addon = 'skin.lumen')

$beta    = $PSScriptRoot
$release = Join-Path (Split-Path $beta -Parent) 'kodi-repo'

function Get-Ver([string]$name) {
    if ($name -match '-([0-9][0-9A-Za-z.]*)\.zip$') { try { return [version]$Matches[1] } catch {} }
    return [version]'0.0.0'
}

$quelle = Get-ChildItem (Join-Path $beta $Addon) -Filter '*.zip' -File -ErrorAction SilentlyContinue |
          Sort-Object { Get-Ver $_.Name } -Descending | Select-Object -First 1
if (-not $quelle) { Write-Host "Keine Beta-ZIP fuer $Addon gefunden." -ForegroundColor Red; exit 1 }

$zielDir = Join-Path $release $Addon
New-Item -ItemType Directory -Path $zielDir -Force | Out-Null
$alt = Get-ChildItem $zielDir -Filter '*.zip' -File | Sort-Object { Get-Ver $_.Name } -Descending | Select-Object -First 1
if ($alt -and (Get-Ver $alt.Name) -gt (Get-Ver $quelle.Name)) {
    Write-Host "Abbruch: Im Release liegt bereits eine neuere Version ($($alt.Name))." -ForegroundColor Red; exit 1
}

Copy-Item $quelle.FullName (Join-Path $zielDir $quelle.Name) -Force
# Bilder (Icon, Fanart, Screenshots) mitnehmen, falls vorhanden
foreach ($n in 'icon.png', 'fanart.jpg') {
    $p = Join-Path $beta "$Addon\$n"; if (Test-Path $p) { Copy-Item $p (Join-Path $zielDir $n) -Force }
}
$res = Join-Path $beta "$Addon\resources"; if (Test-Path $res) { Copy-Item $res $zielDir -Recurse -Force }
Write-Host "Freigegeben: $($quelle.Name)  ->  kodi-repo\$Addon\" -ForegroundColor Green

foreach ($r in $release, $beta) {
    Push-Location $r; & (Join-Path $r 'md5_erzeugen.ps1') | Select-Object -Last 3; Pop-Location
}
Write-Host ""
Write-Host "Jetzt den Inhalt von kodi-repo\ auf GitHub hochladen (Homepage-Links folgen automatisch)." -ForegroundColor Cyan

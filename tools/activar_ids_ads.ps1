# Sustituye los IDs de PRUEBA de AdMob por los IDs REALES del cliente.
#
# Requiere haber creado la cuenta AdMob y el bloque de anuncios (ver
# docs/ADS_CLIENTE.md y docs/DEPLOY_PLAY_STORE.md, punto C).
#
# Uso:
#   powershell -File tools/activar_ids_ads.ps1 `
#     -AppId "ca-app-pub-XXXXXXXXXXXX~YYYYYYYYYY" `
#     -BannerId "ca-app-pub-XXXXXXXXXXXX/ZZZZZZZZZZ" `
#     -RewardedId "ca-app-pub-XXXXXXXXXXXX/WWWWWWWWWW" `
#     -AppOpenId "ca-app-pub-XXXXXXXXXXXX/VVVVVVVVVV"
#
# Despues: flutter analyze + flutter test + flutter build appbundle --release
# y rellenar Data Safety en Play Console con los IDs reales.
#
# Los archivos se reescriben en UTF-8 sin BOM. Para revertir:
#   git checkout -- android/app/src/main/AndroidManifest.xml lib/services/ads_service.dart

param(
    [Parameter(Mandatory = $true)][string]$AppId,      # ca-app-pub-XXXX~YYYY  (ID de app, manifest)
    [Parameter(Mandatory = $true)][string]$BannerId,   # ca-app-pub-XXXX/YYYY  (unit ID banner)
    [Parameter(Mandatory = $true)][string]$RewardedId, # ca-app-pub-XXXX/YYYY  (unit ID recompensado)
    [Parameter(Mandatory = $true)][string]$AppOpenId   # ca-app-pub-XXXX/YYYY  (unit ID app open)
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$enc = New-Object System.Text.UTF8Encoding($false)

function Validate-Id([string]$id, [string]$what) {
    if (-not $id.StartsWith("ca-app-pub-")) {
        throw "El $what no parece un ID de AdMob: $id (debe empezar por ca-app-pub-)"
    }
}

Validate-Id $AppId "AppId"
Validate-Id $BannerId "BannerId"
Validate-Id $RewardedId "RewardedId"
Validate-Id $AppOpenId "AppOpenId"

function Replace-InFile([string]$path, [string]$old, [string]$new, [string]$what) {
    $abs = Join-Path $root $path
    $text = [System.IO.File]::ReadAllText($abs, $enc)
    $count = ([regex]::Matches($text, [regex]::Escape($old))).Count
    if ($count -ne 1) {
        throw "Se esperaba 1 ocurrencia de '$what' en $abs y se encontraron $count. Abortado (nada modificado)."
    }
    [System.IO.File]::WriteAllText($abs, $text.Replace($old, $new), $enc)
    Write-Host "OK  $what -> actualizado en $path"
}

Write-Host "IDs de prueba vigentes:"
Write-Host "  App ID  : ca-app-pub-3940256099942544~3347511713"
Write-Host "  Banner  : ca-app-pub-3940256099942544/6300978111"
Write-Host "  Reward  : ca-app-pub-3940256099942544/5224354917"
Write-Host "  AppOpen : ca-app-pub-3940256099942544/9257395921"
Write-Host "Sustituyendo por los IDs reales...`n"

# 1) ID de aplicacion en el AndroidManifest (etiqueta APPLICATION_ID)
Replace-InFile "android/app/src/main/AndroidManifest.xml" `
    "ca-app-pub-3940256099942544~3347511713" $AppId "AppId (manifest)"

# 2) Unit IDs en lib/services/ads_service.dart (constantes de prueba)
Replace-InFile "lib/services/ads_service.dart" `
    "ca-app-pub-3940256099942544/6300978111" $BannerId "kAdmobBannerTestId"
Replace-InFile "lib/services/ads_service.dart" `
    "ca-app-pub-3940256099942544/5224354917" $RewardedId "kAdmobRewardedTestId"
Replace-InFile "lib/services/ads_service.dart" `
    "ca-app-pub-3940256099942544/9257395921" $AppOpenId "kAdmobAppOpenTestId"

Write-Host "`nListo. Siguientes pasos:"
Write-Host "  1. flutter analyze && flutter test"
Write-Host "  2. flutter build appbundle --release"
Write-Host "  3. Rellenar Data Safety en Play Console con los IDs reales (docs/DATA_SAFETY.md)"
Write-Host "  4. Verificar el flujo UMP end-to-end en un dispositivo EEE"
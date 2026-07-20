# بناء APK للسيرفر (72.60.32.52:8094)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "== flutter build apk (production API) ==" -ForegroundColor Cyan
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://72.60.32.52:8094/api

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Copy-Item $apk "build\app\outputs\flutter-apk\matchy-matchy-release.apk" -Force
    Write-Host "✓ APK: build\app\outputs\flutter-apk\matchy-matchy-release.apk" -ForegroundColor Green
}

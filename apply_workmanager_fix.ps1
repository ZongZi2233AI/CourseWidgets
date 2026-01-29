# PowerShell script to apply workmanager AGP 9.0 fix

$sourceFile = "workmanager_agp9_fix.gradle"
$targetFile = "C:\Users\26390\AppData\Local\Pub\Cache\hosted\pub.dev\workmanager_android-0.9.0+2\android\build.gradle"

Write-Host "Applying workmanager AGP 9.0 fix..." -ForegroundColor Cyan

# Check if source file exists
if (-not (Test-Path $sourceFile)) {
    Write-Host "Error: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}

# Check if target directory exists
$targetDir = Split-Path $targetFile -Parent
if (-not (Test-Path $targetDir)) {
    Write-Host "Error: Target directory not found: $targetDir" -ForegroundColor Red
    Write-Host "Make sure workmanager plugin is installed (run 'flutter pub get' first)" -ForegroundColor Yellow
    exit 1
}

# Backup original file
$backupFile = "$targetFile.backup"
if (Test-Path $targetFile) {
    Write-Host "Creating backup: $backupFile" -ForegroundColor Yellow
    Copy-Item $targetFile $backupFile -Force
}

# Read source file and remove comment lines
$content = Get-Content $sourceFile | Where-Object { $_ -notmatch "^// (Fixed|Replace|with)" }

# Write to target file
$content | Set-Content $targetFile -Force

Write-Host "✓ Fix applied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run: flutter clean" -ForegroundColor White
Write-Host "2. Run: flutter pub get" -ForegroundColor White
Write-Host "3. Run: flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "If you need to restore the original file, it's backed up at:" -ForegroundColor Yellow
Write-Host $backupFile -ForegroundColor Gray

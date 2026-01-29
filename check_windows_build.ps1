# Windows 构建检查脚本
# 检查构建产物和图标文件

Write-Host "=== Windows 构建检查 ===" -ForegroundColor Cyan
Write-Host ""

# 检查 EXE 文件
$exePath = "build\windows\x64\runner\Release\CourseWidgets.exe"
if (Test-Path $exePath) {
    $exeInfo = Get-Item $exePath
    Write-Host "✅ EXE 文件存在" -ForegroundColor Green
    Write-Host "   路径: $exePath"
    Write-Host "   大小: $([math]::Round($exeInfo.Length / 1MB, 2)) MB"
    Write-Host "   修改时间: $($exeInfo.LastWriteTime)"
} else {
    Write-Host "❌ EXE 文件不存在" -ForegroundColor Red
    Write-Host "   请运行: flutter build windows --release"
}
Write-Host ""

# 检查图标文件
Write-Host "=== 图标文件检查 ===" -ForegroundColor Cyan
Write-Host ""

# 检查源图标
$sourceIcon = "assets\app_icon.ico"
if (Test-Path $sourceIcon) {
    $iconInfo = Get-Item $sourceIcon
    Write-Host "✅ 源图标存在" -ForegroundColor Green
    Write-Host "   路径: $sourceIcon"
    Write-Host "   大小: $([math]::Round($iconInfo.Length / 1KB, 2)) KB"
} else {
    Write-Host "❌ 源图标不存在" -ForegroundColor Red
    Write-Host "   请运行: python generate_windows_icon.py"
}
Write-Host ""

# 检查打包后的图标
$builtIcon = "build\windows\x64\runner\Release\data\flutter_assets\assets\app_icon.ico"
if (Test-Path $builtIcon) {
    $builtIconInfo = Get-Item $builtIcon
    Write-Host "✅ 打包图标存在" -ForegroundColor Green
    Write-Host "   路径: $builtIcon"
    Write-Host "   大小: $([math]::Round($builtIconInfo.Length / 1KB, 2)) KB"
} else {
    Write-Host "❌ 打包图标不存在" -ForegroundColor Red
    Write-Host "   这可能导致托盘图标不显示"
    Write-Host "   请重新构建: flutter build windows --release"
}
Write-Host ""

# 检查 Windows 资源图标
$resourceIcon = "windows\runner\resources\app_icon.ico"
if (Test-Path $resourceIcon) {
    $resIconInfo = Get-Item $resourceIcon
    Write-Host "✅ Windows 资源图标存在" -ForegroundColor Green
    Write-Host "   路径: $resourceIcon"
    Write-Host "   大小: $([math]::Round($resIconInfo.Length / 1KB, 2)) KB"
} else {
    Write-Host "❌ Windows 资源图标不存在" -ForegroundColor Red
    Write-Host "   请运行: python generate_windows_icon.py"
}
Write-Host ""

# 检查所有 ICO 文件
Write-Host "=== 所有 ICO 文件 ===" -ForegroundColor Cyan
Write-Host ""
Get-ChildItem -Path "build\windows\x64\runner\Release" -Filter "*.ico" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "📁 $($_.FullName)" -ForegroundColor Yellow
    Write-Host "   大小: $([math]::Round($_.Length / 1KB, 2)) KB"
}
Write-Host ""

# 运行建议
Write-Host "=== 运行建议 ===" -ForegroundColor Cyan
Write-Host ""
if (Test-Path $exePath) {
    Write-Host "1. 运行应用:" -ForegroundColor Green
    Write-Host "   .\build\windows\x64\runner\Release\CourseWidgets.exe"
    Write-Host ""
    Write-Host "2. 检查控制台输出，查找:" -ForegroundColor Green
    Write-Host "   - ✅ 托盘初始化成功"
    Write-Host "   - ✅ Windows托盘初始化完成"
    Write-Host ""
    Write-Host "3. 检查托盘区域:" -ForegroundColor Green
    Write-Host "   - 查看任务栏右下角"
    Write-Host "   - 点击向上箭头查看隐藏图标"
    Write-Host ""
} else {
    Write-Host "请先构建应用:" -ForegroundColor Yellow
    Write-Host "   flutter build windows --release"
    Write-Host ""
}

Write-Host "=== 检查完成 ===" -ForegroundColor Cyan

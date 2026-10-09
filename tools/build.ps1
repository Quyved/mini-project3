param(
    [ValidateSet('debug','release')][string]$Mode = 'debug',
    [string]$FlutterSdk = '',
    [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
    [switch]$SkipChecks,
    [switch]$VerboseBuild,
    [switch]$StorageMirror
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
if ($FlutterSdk) {
    $flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
} else {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if (!$command) { throw 'Cần Flutter 3.44+ (khuyến nghị 3.47.7). Dùng -FlutterSdk đường_dẫn_SDK hoặc thêm flutter vào PATH.' }
    $flutter = $command.Source
}
if (!(Test-Path -LiteralPath $flutter)) { throw "Không tìm thấy Flutter: $flutter" }
if ($StorageMirror) {
    $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
    Write-Host "Flutter engine mirror: $env:FLUTTER_STORAGE_BASE_URL"
}
$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:PUB_CACHE = Join-Path $PWD '.local-cache\pub'
$env:GRADLE_USER_HOME = Join-Path $PWD '.local-cache\gradle'
$env:TEMP = Join-Path $PWD '.local-cache\tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force $env:TEMP | Out-Null
$jbr = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path -LiteralPath "$jbr\bin\java.exe") { $env:JAVA_HOME = $jbr }
if ($Mode -eq 'release' -and !(Test-Path -LiteralPath 'android\key.properties')) {
    throw 'Cần cấu hình android/key.properties và keystore riêng. Xem README phần ký release.'
}
function Run-Flutter([string[]]$CommandArguments) {
    & $flutter @CommandArguments
    if ($LASTEXITCODE -ne 0) { throw "Flutter thất bại: $($CommandArguments -join ' ')" }
}
Run-Flutter -CommandArguments @('--version')
Run-Flutter -CommandArguments @('pub', 'get')
if (!$SkipChecks) {
    $dart = Join-Path (Split-Path $flutter -Parent) 'dart.bat'
    & $dart format lib test integration_test
    if ($LASTEXITCODE -ne 0) { throw 'dart format thất bại' }
    Run-Flutter -CommandArguments @('analyze')
    Run-Flutter -CommandArguments @('test')
}
# Let Flutter regenerate the plugin registrant for the selected build mode.
$buildArguments = @('build', 'apk', "--$Mode")
if ($VerboseBuild) { $buildArguments += '--verbose' }
Run-Flutter -CommandArguments $buildArguments
Write-Host "APK: $PWD\build\app\outputs\flutter-apk\app-$Mode.apk"

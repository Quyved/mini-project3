$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$cacheRoot = Join-Path $projectRoot '.local-cache\gradle'
Write-Host ("Build snapshot: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

# FileInfo metadata can lag while Java keeps a download open on Windows.
# Read the open stream length to obtain the current number of downloaded bytes.
$downloadRoot = Join-Path $cacheRoot '.tmp'
if (Test-Path -LiteralPath $downloadRoot) {
    foreach ($download in (Get-ChildItem -LiteralPath $downloadRoot -Filter 'gradle_download*' -File)) {
        $stream = $null
        try {
            $stream = [System.IO.File]::Open($download.FullName,
                [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite)
            Write-Host ('Download {0}: {1:N1} MB' -f $download.Name, ($stream.Length / 1000000))
        } catch {
            Write-Host ('Download {0}: closed or moved by Gradle' -f $download.Name)
        } finally {
            if ($stream) { $stream.Dispose() }
        }
    }
}

$daemonRoot = Join-Path $cacheRoot 'daemon'
if (Test-Path -LiteralPath $daemonRoot) {
    $latestLog = Get-ChildItem -LiteralPath $daemonRoot -Recurse -File -Filter 'daemon-*.out.log' |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog) {
        Write-Host ("Latest Gradle log: " + $latestLog.FullName)
        Get-Content -LiteralPath $latestLog.FullName -Tail 15
    }
}

$apkRoot = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
$apks = @(Get-ChildItem -LiteralPath $apkRoot -Filter '*.apk' -File -ErrorAction SilentlyContinue)
if ($apks.Count -eq 0) {
    Write-Host 'APK has not been created yet.'
} else {
    foreach ($apk in $apks) {
        Write-Host ('APK: {0} ({1:N1} MB), modified {2}' -f
            $apk.FullName, ($apk.Length / 1000000), $apk.LastWriteTime)
    }
}

param(
    [switch]$Prod,
    [switch]$NoDeploy,
    [string]$Scope = "phidanghai-specs-projects"
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $RepoRoot "build\web"
$ExportHtml = Join-Path $BuildDir "index.html"
$VercelConfigSrc = Join-Path $PSScriptRoot "vercel.web.json"

function Resolve-GodotCli {
    $cmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $localGodot = "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
    if (Test-Path $localGodot) { return $localGodot }
    throw "Không tìm thấy Godot CLI (godot trong PATH hoặc $localGodot)."
}

function Resolve-VercelCli {
    $cmd = Get-Command vercel -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $appdataCmd = Join-Path $env:APPDATA "npm\vercel.cmd"
    if (Test-Path $appdataCmd) { return $appdataCmd }
    throw "Không tìm thấy Vercel CLI. Hãy chạy 'npm install -g vercel' rồi thử lại."
}

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# 1) Export Web (HTML5) release
$Godot = Resolve-GodotCli
Write-Host "Đang xuất bản Web (HTML5) release..."
Push-Location $RepoRoot
try {
    & $Godot --headless --path $RepoRoot --export-release "Web (HTML5)" $ExportHtml
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Godot export thất bại với mã thoát $LASTEXITCODE."
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

# 2) Verify required output files & print pck/wasm sizes
$requiredFiles = @("index.html", "index.js", "index.pck", "index.wasm")
foreach ($f in $requiredFiles) {
    $fp = Join-Path $BuildDir $f
    if (-not (Test-Path $fp)) {
        Write-Error "Thiếu file sau khi export: $fp"
        exit 1
    }
}

$pckSize = (Get-Item (Join-Path $BuildDir "index.pck")).Length
$wasmSize = (Get-Item (Join-Path $BuildDir "index.wasm")).Length
Write-Host ("Kích thước index.pck : {0:N0} bytes ({1:N2} MB)" -f $pckSize, ($pckSize / 1MB))
Write-Host ("Kích thước index.wasm: {0:N0} bytes ({1:N2} MB)" -f $wasmSize, ($wasmSize / 1MB))

# 3) Copy tools\vercel.web.json -> build\web\vercel.json
Copy-Item -Force $VercelConfigSrc (Join-Path $BuildDir "vercel.json")

# 4) Stop early if -NoDeploy
if ($NoDeploy) {
    Write-Host "Bản xuất đã sẵn sàng tại build\web (chưa triển khai)"
    exit 0
}

# 5) Check Vercel login
$Vercel = Resolve-VercelCli
$prevPref = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$null = & $Vercel whoami 2>$null
$whoamiExit = $LASTEXITCODE
$ErrorActionPreference = $prevPref
if ($whoamiExit -ne 0) {
    Write-Host "Chưa đăng nhập Vercel. Hãy chạy 'vercel login' rồi chạy lại."
    exit 1
}

# 6) Link project at repo root if needed, then copy .vercel to build\web\.vercel
$RootVercelDir = Join-Path $RepoRoot ".vercel"
$RootProjectJson = Join-Path $RootVercelDir "project.json"
if (-not (Test-Path $RootProjectJson)) {
    Push-Location $RepoRoot
    try {
        & $Vercel link --yes --project chibi-farmer --scope $Scope
        if ($LASTEXITCODE -ne 0) {
            Write-Error "vercel link thất bại với mã thoát $LASTEXITCODE."
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }
}

$BuildVercelDir = Join-Path $BuildDir ".vercel"
if (Test-Path $BuildVercelDir) {
    Remove-Item -Recurse -Force $BuildVercelDir
}
Copy-Item -Recurse -Force $RootVercelDir $BuildVercelDir

# 7) Deploy from build\web
Push-Location $BuildDir
try {
    if ($Prod) {
        Write-Host "Đang triển khai bản PRODUCTION lên Vercel..."
        $deployOut = & $Vercel deploy --prod --yes
    } else {
        Write-Host "Đang triển khai bản PREVIEW lên Vercel..."
        $deployOut = & $Vercel deploy --yes
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "vercel deploy thất bại với mã thoát $LASTEXITCODE."
        exit $LASTEXITCODE
    }
    $url = ($deployOut | Select-String -Pattern "https://[^\s]+" | Select-Object -Last 1).Matches.Value
    if ($url) {
        Write-Host "URL triển khai: $url"
    } else {
        Write-Host ($deployOut -join "`n")
    }
} finally {
    Pop-Location
}

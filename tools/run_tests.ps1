param(
    [switch]$ContinueOnFail = $true
)

$GodotExe = "D:\Gotdot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$ArgsList = @(
    "--headless",
    "--path", $ProjectRoot,
    "-s", "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
    "-a", "res://tests/unit",
    "-a", "res://tests/playtest"
)
if ($ContinueOnFail) {
    $ArgsList += "-c"
}
$ArgsList += "--ignoreHeadlessMode"

$Output = & $GodotExe @ArgsList 2>&1
$ExitCode = $LASTEXITCODE

$Output | ForEach-Object {
    $CleanLine = ($_ -as [string]) -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
    if ($CleanLine -match 'FAILURE|ERROR|WARNING|Overall Summary|Executed test cases|Exit code|passed|failed') {
        Write-Output $CleanLine
    }
}

Write-Output "Exit code: $ExitCode"
exit $ExitCode

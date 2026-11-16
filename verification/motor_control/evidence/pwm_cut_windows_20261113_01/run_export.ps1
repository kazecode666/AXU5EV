$ErrorActionPreference = 'Stop'
$start = [DateTimeOffset]::UtcNow
$exe = 'D:/Software/2026.1/Vivado/bin/vivado.bat'
$dir = $PSScriptRoot
$argsLine = '/d /s /c ""' + $exe + '" -mode batch -source "' + $dir + '/export_cut.tcl" -log "' + $dir + '/vivado_export.log" -journal "' + $dir + '/vivado_export.jou""'
$p = Start-Process -FilePath $env:ComSpec -ArgumentList $argsLine -WorkingDirectory $dir -RedirectStandardOutput "$dir/export.stdout.log" -RedirectStandardError "$dir/export.stderr.log" -PassThru
$timedOut = -not $p.WaitForExit(1800000)
if ($timedOut) { & taskkill /PID $p.Id /T /F; $p.WaitForExit() }
$p.Refresh()
@{started_utc=$start.ToString('o');finished_utc=[DateTimeOffset]::UtcNow.ToString('o');elapsed_seconds=([DateTimeOffset]::UtcNow-$start).TotalSeconds;pid=$p.Id;timed_out=$timedOut;exit_code=$p.ExitCode;limit_seconds=1800} | ConvertTo-Json | Set-Content -LiteralPath "$dir/export.process.json" -Encoding utf8
if ($timedOut) {exit 124}; exit $p.ExitCode

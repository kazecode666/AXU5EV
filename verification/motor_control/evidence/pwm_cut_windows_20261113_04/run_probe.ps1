$ErrorActionPreference='Stop'
$dir=$PSScriptRoot
$start=[DateTimeOffset]::UtcNow
$argsLine='/d /s /c ""D:/Software/2026.1/Vivado/bin/vivado.bat" -mode batch -source "'+$dir+'/probe_polarity.tcl" -log "'+$dir+'/probe.log" -journal "'+$dir+'/probe.jou""'
$p=Start-Process -FilePath $env:ComSpec -ArgumentList $argsLine -WorkingDirectory $dir -RedirectStandardOutput "$dir/probe.stdout.log" -RedirectStandardError "$dir/probe.stderr.log" -PassThru
$timeout=-not $p.WaitForExit(600000)
if($timeout){taskkill /PID $p.Id /T /F;$p.WaitForExit()}
@{started_utc=$start.ToString('o');finished_utc=[DateTimeOffset]::UtcNow.ToString('o');elapsed_seconds=([DateTimeOffset]::UtcNow-$start).TotalSeconds;limit_seconds=600;timed_out=$timeout;pid=$p.Id;exit_code=$p.ExitCode} | ConvertTo-Json | Set-Content "$dir/probe.process.json" -Encoding utf8
if($timeout){exit 124}
if(Test-Path "$dir/probe_status.txt"){if((Get-Content "$dir/probe_status.txt" -Raw) -match '^COMPLETED'){exit 0}}
exit 1
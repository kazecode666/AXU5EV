[CmdletBinding()]
param(
 [ValidateSet('inputs','snapshot','current','observer','observer_min','all')][string]$Suite='all',
 [string]$RunDir,
 [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin'
)
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $RunDir){$RunDir=Join-Path $axRoot ('.runtime/ax03b1/rtl_'+[guid]::NewGuid().ToString('N'))}
$RunDir=[IO.Path]::GetFullPath($RunDir)
$axRuntime=[IO.Path]::GetFullPath((Join-Path $axRoot '.runtime/ax03b1'))
if(-not $RunDir.StartsWith($axRuntime+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'RunDir must be a new subdirectory of .runtime/ax03b1'}
if(Test-Path -LiteralPath $RunDir){throw 'RunDir already exists; select a new path to preserve evidence'}
New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
function Quote-B1([string]$value){
 if($value -match '["&|<>^%!\r\n]'){throw 'Unsupported tool argument metacharacter'}
 return '"'+$value+'"'
}
function Invoke-B1Tool([string]$name,[string[]]$Arguments,[string]$Directory){
 $bat=Join-Path $VivadoBin ($name+'.bat')
 if(-not (Test-Path -LiteralPath $bat)){throw "Missing tool: $bat"}
 $words=@((Quote-B1 $bat))+@($Arguments|ForEach-Object{Quote-B1 $_})
 $psi=[Diagnostics.ProcessStartInfo]::new()
 $psi.FileName=$env:ComSpec;$psi.Arguments='/d /s /c "'+($words -join ' ')+'"'
 $psi.WorkingDirectory=$Directory;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $process=[Diagnostics.Process]::new();$process.StartInfo=$psi
 if(-not $process.Start()){throw "$name failed to start"}
 $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 $finished=$process.WaitForExit(300000)
 if(-not $finished){$process.Kill();throw "$name timed out"}
 $output=$stdout.GetAwaiter().GetResult()+[Environment]::NewLine+$stderr.GetAwaiter().GetResult()
 [IO.File]::WriteAllText((Join-Path $Directory ($name+'.console.log')),$output,[Text.UTF8Encoding]::new($false))
 if($process.ExitCode -ne 0 -or $output -match '(?im)^(ERROR:|FATAL:|Fatal:|Error:).*'){
  Write-Output ($output -split '\r?\n' | Select-Object -Last 20)
  throw "$name failed; see $Directory"
 }
 return $output
}
# Only this new observer family is compiled; no PR24/FOC build or hardware tool.
$rtl=@(Get-ChildItem -LiteralPath (Join-Path $axRoot 'integration/rtl/ax03b1') -File | Where-Object Extension -eq '.sv' | Sort-Object Name | ForEach-Object FullName)
$generated=@()
$genDir=Join-Path $axRoot 'generated/ax03b1'
if(Test-Path -LiteralPath $genDir){
 $generated=@(Get-ChildItem -LiteralPath $genDir -File -Recurse | Where-Object { $_.Extension -in '.v','.sv' -and $_.Name -notmatch '_tb\.' } | Sort-Object @{Expression={if($_.Name -match 'pkg|package'){0}else{1}}},Name | ForEach-Object FullName)
}
$cases=[ordered]@{
 inputs=@{top='ax03b1_input_tb';tb='input_tb.sv';pass='TEST_PASS AX03B1_INPUT'}
 snapshot=@{top='snapshot_tb';tb='snapshot_tb.sv';pass='SNAPSHOT_PASS'}
 current=@{top='ax03b1_current_tb';tb='current_tb.sv';pass='AX03B1_CURRENT_PASS'}
 observer=@{top='ax03b1_observer_tb';tb='observer_tb.sv';pass='AX03B1_OBSERVER_PASS'}
 observer_min=@{top='ax03b1_observer_fast_tb';tb='observer_tb.sv';pass='AX03B1_OBSERVER_PASS'}
}
$selected=if($Suite -eq 'all'){@($cases.Keys)}else{@($Suite)}
$results=@()
foreach($key in $selected){
 $case=$cases[$key];$work=Join-Path $RunDir $key;New-Item -ItemType Directory -Path $work | Out-Null
 $tb=Join-Path $axRoot ('verification/ax03b1/'+$case.tb)
 if(-not(Test-Path -LiteralPath $tb)){throw "Missing testbench $tb"}
 $sources=@($generated)+@($rtl)+@($tb)
 $compile=Invoke-B1Tool 'xvlog' (@('-sv')+$sources) $work
 $elaborate=Invoke-B1Tool 'xelab' @("work.$($case.top)",'-s',"b1_$key",'-debug','off','-timescale','1ns/1ps') $work
 $sim=Invoke-B1Tool 'xsim' @("b1_$key",'-runall') $work
 $passLine=@($sim -split '\r?\n' | Where-Object {$_ -match $case.pass})
 if($passLine.Count -eq 0){throw "Test ended without required PASS marker: $key"}
 Write-Output ($passLine -join [Environment]::NewLine)
 $results+=@([ordered]@{suite=$key;status='PASS';top=$case.top;pass_marker=$passLine;log_directory=$work})
}
$summary=[ordered]@{status='PASS';kind='NEW_RTL_BEHAVIORAL_ONLY';run_dir=$RunDir;results=$results;board='NOT_RUN';synthesis='NOT_RUN';implementation='NOT_RUN';physical_timing_cdc='NOT_RUN'}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
Write-Output ('AX03B1_RTL_PASS '+(Join-Path $RunDir 'summary.json'))

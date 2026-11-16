[CmdletBinding()]
param([ValidateSet('chain','mapper','timing-preflight')][string]$Suite='chain',[string]$RunDir,[string]$Vectors,
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin',
      [switch]$BadAdoptionExpectation)
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $RunDir){$RunDir=Join-Path $axRoot ('.runtime/motor_control/rtl_'+[guid]::NewGuid().ToString('N'))}
$RunDir=[IO.Path]::GetFullPath($RunDir)
if(Test-Path -LiteralPath $RunDir){throw 'RunDir exists; choose a new directory to preserve previous results'}
New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
function Quote-B2([string]$value){
 if($value -match '["&|<>^%!\r\n]'){throw 'Unsupported tool argument metacharacter'}
 return '"'+$value+'"'
}
function Invoke-B2Tool([string]$name,[string[]]$Arguments,[string]$Directory){
 $bat=Join-Path $VivadoBin ($name+'.bat')
 if(-not (Test-Path -LiteralPath $bat)){throw "Missing tool: $bat"}
 $words=@((Quote-B2 $bat))+@($Arguments|ForEach-Object{Quote-B2 $_})
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
# Compile the same explicit handwritten/generated manifest as the board entry.
$manifest=Join-Path $axRoot 'hardware/axu5ev/motor_control/sources.list'
$sources=@(Get-Content -LiteralPath $manifest | ForEach-Object {
 $entry=$_ -split '\|',2
 if($entry[0] -in @('handwritten','generated','generated_foc')) {Join-Path $axRoot $entry[1]}
})
$defines=@()
if($BadAdoptionExpectation -and $Suite -ne 'timing-preflight'){throw 'Counterexample is only for timing-preflight'}
if($Suite -eq 'timing-preflight'){
 $sources += @(Join-Path $axRoot 'verification/motor_control/timing_tb.sv')
 $top='timing_tb';$defines=@('-d','MC_TIMING_RTL')
}elseif($Suite -eq 'mapper'){
 if(-not $Vectors -or -not (Test-Path -LiteralPath $Vectors)){throw 'Pass the model-generated duty vectors file'}
 Copy-Item -LiteralPath $Vectors -Destination (Join-Path $RunDir 'duty_vectors.txt')
 $sources += @(Join-Path $axRoot 'verification/motor_control/mapper_tb.sv')
 $top='mapper_tb'
}else{
 $sources += @(Join-Path $axRoot 'verification/motor_control/chain_tb.sv')
 $top='chain_tb'
}
$compile=Invoke-B2Tool 'xvlog' (@('-sv')+$defines+$sources) $RunDir
$elaborate=Invoke-B2Tool 'xelab' @(('work.'+$top),'-s','b2_interface','-debug','off','-timescale','1ns/1ps') $RunDir
$simArguments=@('b2_interface','-runall')
if($BadAdoptionExpectation){$simArguments+=@('-testplusarg','BAD_ADOPT_EXPECTATION')}
$simulation=Invoke-B2Tool 'xsim' $simArguments $RunDir
$marker=@($simulation -split '\r?\n' | Where-Object {$_ -match '^MOTOR_(CHAIN|MAPPER|TIMING_RTL)_PASS '})
if($marker.Count -ne 1){throw 'New interface simulation did not produce its PASS marker'}
$summary=[ordered]@{status='PASS';scope='ADC_QEP_FOC_PWM';pass_marker=$marker[0];run_dir=$RunDir;board='NOT_RUN';old_pr24_b1_regression='NOT_RUN'}
if($Suite -eq 'timing-preflight'){$summary.scope='TIMING_TESTBENCH_PREFLIGHT_NOT_SDF'}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Write-Output $marker[0]
Write-Output ('MOTOR_CONTROL_RTL_PASS '+(Join-Path $RunDir 'summary.json'))

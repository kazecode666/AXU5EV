[CmdletBinding()]
param([ValidateSet('chain','mapper','timing-preflight','ax04b-chain','ax04b-axi')][string]$Suite='chain',[string]$RunDir,[string]$Vectors,
      [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin',
      [ValidateSet('SELFTEST','REAL')][string]$Ax04bMode='SELFTEST',
      [switch]$BadAdoptionExpectation,[switch]$Ax05aObservation)
$ErrorActionPreference='Stop'
$axRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if(-not $RunDir){
 $localDirectory=if($Suite.StartsWith('ax04b-')){'.runtime/experiment/ax04b'}else{'.runtime/motor_control'}
 $RunDir=Join-Path (Join-Path $axRoot $localDirectory) ('rtl_'+[guid]::NewGuid().ToString('N'))
}
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
$generics=@()
if($BadAdoptionExpectation -and $Suite -ne 'timing-preflight'){throw 'Counterexample is only for timing-preflight'}
if($Ax05aObservation -and $Suite -ne 'ax04b-chain'){throw 'AX05A observation uses ax04b-chain'}
if($Suite -eq 'ax04b-chain'){
 $sources=@(Get-Content -LiteralPath $manifest | ForEach-Object {
  $entry=$_ -split '\|',2
  if($entry[0] -in @('handwritten','experiment')) {
   $relative=$entry[1]
   if($Ax05aObservation -and (Split-Path -Leaf $relative) -in @(
       'AX04_FOC_FOC_DUT.sv','AX04_FOC_Id.sv','AX04_FOC_dq_voltage_limiter.sv')){
    $relative=$relative.Replace('generated/experiment/ax04_01/pl/AXU5EV_Experiment_FOC/',
      'generated/experiment/ax05a_03/pl/AXU5EV_Experiment_FOC/')
   }
   Join-Path $axRoot $relative
  }
 })
 $sources += @(Join-Path $axRoot 'verification/experiment/ax04b/ax04b_chain_tb.sv')
 $top='ax04b_chain_tb';$defines=@('-d','AX04B_EXPERIMENT')
 if($Ax05aObservation){$defines+=@('-d','AX05A_FOC_OBSERVATION')}
 if($Ax04bMode -eq 'REAL'){$generics=@('-generic_top','SELFTEST=0')}
}elseif($Suite -eq 'ax04b-axi'){
 $sources=@((Join-Path $axRoot 'hardware/axu5ev/motor_control/rtl/axi/ax04b_realtime_axi.sv'),
            (Join-Path $axRoot 'verification/experiment/ax04b/ax04b_realtime_axi_tb.sv'))
 $top='ax04b_realtime_axi_tb'
}elseif($Suite -eq 'timing-preflight'){
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
$elaborate=Invoke-B2Tool 'xelab' (@(('work.'+$top),'-s','b2_interface','-debug','off','-timescale','1ns/1ps')+$generics) $RunDir
$simArguments=@('b2_interface','-runall')
if($BadAdoptionExpectation){$simArguments+=@('-testplusarg','BAD_ADOPT_EXPECTATION')}
$simulation=Invoke-B2Tool 'xsim' $simArguments $RunDir
$marker=@($simulation -split '\r?\n' | Where-Object {$_ -match '^(MOTOR_(CHAIN|MAPPER|TIMING_RTL)_PASS|AX04B_(REALTIME_AXI|CHAIN) PASS) '})
if($marker.Count -ne 1){throw 'New interface simulation did not produce its PASS marker'}
$summary=[ordered]@{status='PASS';scope='ADC_QEP_FOC_PWM';pass_marker=$marker[0];run_dir=$RunDir;board='NOT_RUN';old_pr24_b1_regression='NOT_RUN'}
if($Suite -eq 'timing-preflight'){$summary.scope='TIMING_TESTBENCH_PREFLIGHT_NOT_SDF'}
if($Suite -eq 'ax04b-chain'){$summary.scope='AX04B_ADC_IRQ_AXI_FOC_PWM';$summary.mode=$Ax04bMode}
if($Suite -eq 'ax04b-axi'){$summary.scope='AX04B_ATOMIC_FEEDBACK_AND_REFERENCE'}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Write-Output $marker[0]
Write-Output ('MOTOR_CONTROL_RTL_PASS '+(Join-Path $RunDir 'summary.json'))

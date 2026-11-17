[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$RunDir,
 [Parameter(Mandatory=$true)][string]$AngleVectors,
 [string]$VivadoBin='E:/AMDDesignTools/2026.1/Vivado/bin'
)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$RunDir=[IO.Path]::GetFullPath($RunDir)
$AngleVectors=[IO.Path]::GetFullPath($AngleVectors)
if(Test-Path -LiteralPath $RunDir){throw 'Choose a new result directory to preserve existing evidence'}
if(-not(Test-Path -LiteralPath $AngleVectors -PathType Leaf)){throw "Missing angle vectors: $AngleVectors"}

function Quote-NumericArgument([string]$value){
 if($value -match '["&|<>^%!\r\n]'){throw 'Unsupported tool argument metacharacter'}
 return '"'+$value+'"'
}

function Invoke-NumericTool([string]$name,[string[]]$Arguments,[string]$Directory){
 $batch=Join-Path $VivadoBin ($name+'.bat')
 if(-not(Test-Path -LiteralPath $batch -PathType Leaf)){throw "Missing tool: $batch"}
 $quoted=@((Quote-NumericArgument $batch))+@($Arguments|ForEach-Object{Quote-NumericArgument $_})
 $startInfo=[Diagnostics.ProcessStartInfo]::new()
 $startInfo.FileName=$env:ComSpec
 $startInfo.Arguments='/d /s /c "'+($quoted -join ' ')+'"'
 $startInfo.WorkingDirectory=$Directory
 $startInfo.UseShellExecute=$false
 $startInfo.CreateNoWindow=$true
 $startInfo.RedirectStandardOutput=$true
 $startInfo.RedirectStandardError=$true
 $process=[Diagnostics.Process]::new()
 $process.StartInfo=$startInfo
 if(-not $process.Start()){throw "$name failed to start"}
 $stdout=$process.StandardOutput.ReadToEndAsync()
 $stderr=$process.StandardError.ReadToEndAsync()
 if(-not $process.WaitForExit(300000)){
  $process.Kill()
  throw "$name timed out; inspect $Directory"
 }
 $output=$stdout.GetAwaiter().GetResult()+[Environment]::NewLine+$stderr.GetAwaiter().GetResult()
 [IO.File]::WriteAllText((Join-Path $Directory ($name+'.console.log')),$output,[Text.UTF8Encoding]::new($false))
 if($process.ExitCode -ne 0 -or $output -match '(?im)^(ERROR:|FATAL:|Fatal:|Error:)'){
  throw "$name failed; inspect $Directory"
 }
 return $output
}

# Each work directory compiles only its candidate numeric HDL and existing TB.
$cases=@(
 [ordered]@{
  name='current';top='ax03b1_current_tb';marker='^AX03B1_CURRENT_PASS '
  generated='generated/dsp_reuse/adc/AXU5EV_ADC_HDL';module='Current_Preprocess.sv'
  extra=@('hardware/axu5ev/motor_control/rtl/adc/ax03b1_current_adapter.sv','verification/ax03b1/current_tb.sv')
 },
 [ordered]@{
  name='angle';top='angle_tb';marker='^ANGLE_PASS '
  generated='generated/dsp_reuse/angle/AXU5EV_Encoder_Angle_HDL';module='Encoder_Angle.sv'
  extra=@('verification/encoder_feedback/angle_tb.sv')
 }
)
foreach($case in $cases){
 $directory=Join-Path $taskRoot $case.generated
 if(-not(Test-Path -LiteralPath (Join-Path $directory $case.module) -PathType Leaf)){
  throw "Missing generated module: $directory/$($case.module)"
 }
}
New-Item -ItemType Directory -Path $RunDir | Out-Null
$results=@()
foreach($case in $cases){
 $work=Join-Path $RunDir $case.name
 New-Item -ItemType Directory -Path $work | Out-Null
 $generated=@(Get-ChildItem -LiteralPath (Join-Path $taskRoot $case.generated) -Filter '*.sv' -File -Recurse |
  Sort-Object @{Expression={if($_.Name -match 'pkg|package'){0}else{1}}},Name | ForEach-Object FullName)
 $sources=$generated+@($case.extra|ForEach-Object{Join-Path $taskRoot $_})
 $null=Invoke-NumericTool 'xvlog' (@('-sv')+$sources) $work
 $snapshot='task1_'+$case.name
 $null=Invoke-NumericTool 'xelab' @("work.$($case.top)",'-s',$snapshot,'-debug','off','-timescale','1ns/1ps') $work
 $simulationArgs=@($snapshot,'-runall')
 if($case.name -eq 'angle'){
  $simulationArgs=@($snapshot,'-testplusarg',('VECTORS='+$AngleVectors.Replace('\','/')),'-runall')
 }
 $output=Invoke-NumericTool 'xsim' $simulationArgs $work
 $pass=@($output -split '\r?\n'|Where-Object{$_ -match $case.marker})
 if($pass.Count -ne 1){throw "Missing unique PASS marker for $($case.name); inspect $work"}
 Write-Output $pass[0]
 $results+=@([ordered]@{
  suite=$case.name;status='PASS';top=$case.top;pass_marker=$pass[0]
  generated_directory=$case.generated;generated_file_count=$generated.Count;log_directory=$work
 })
}
$summary=[ordered]@{
 status='PASS';scope='EXTRACTED_NUMERIC_RTL_ONLY';results=$results
 current_cases='Existing current_tb arithmetic, independent calibration, 1024-sample window and boundary assertions'
 angle_vectors=$AngleVectors;board='NOT_RUN';synthesis='NOT_RUN';implementation='NOT_RUN';physical_timing_cdc='NOT_RUN'
}
[IO.File]::WriteAllText((Join-Path $RunDir 'summary.json'),($summary|ConvertTo-Json -Depth 6),[Text.UTF8Encoding]::new($false))
Write-Output ('TASK1_NUMERIC_RTL_PASS '+(Join-Path $RunDir 'summary.json'))

param([Parameter(Mandatory=$true)][string]$RunDir)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$runPath=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RunDir)
if(Test-Path -LiteralPath $runPath){throw 'Choose a new test result directory'}
$stubDir=Join-Path $runPath 'scripts'
New-Item -ItemType Directory -Path $stubDir -Force | Out-Null
$entry=Join-Path $stubDir 'pwm_adc_build_hw.ps1'
Copy-Item -LiteralPath "$repoRoot/scripts/pwm_adc_build_hw.ps1" -Destination $entry
# Exercise the real wrapper with a sibling build stub. No vendor tools run.
@'
param([string]$Stage,[string]$Output)
if($env:MC_PWM -cne '1' -or $env:AX03B3_TEST -cne '0'){
 throw 'PWM_BUILD_STUB_ENV_MISMATCH'
}
if($Output.EndsWith('_throw')){throw 'PWM_BUILD_STUB_FAILURE'}
'PWM_BUILD_STUB_OK'
'@ | Set-Content -LiteralPath (Join-Path $stubDir 'ax03b3_build_hw.ps1') -Encoding ASCII

$savedLocation=Get-Location
$savedEnvironment=[Environment]::GetEnvironmentVariables('Process')
$results=@()
try {
 foreach($mcPresent in @($false,$true)){
  foreach($testPresent in @($false,$true)){
   foreach($shouldThrow in @($false,$true)){
    $mcValue=$null
    $testValue=$null
    if($mcPresent){$mcValue='0'}
    if($testPresent){$testValue='1'}
    $env:MC_PWM=$mcValue
    $env:AX03B3_TEST=$testValue
    $caseName='mc{0}_test{1}_{2}' -f [int]$mcPresent,[int]$testPresent,@('success','throw')[[int]$shouldThrow]
    $caught=$false
    try {
     $output=@(& $entry -Stage validate -Output (Join-Path $runPath $caseName))
     if($output.Count -ne 1 -or $output[0] -cne 'PWM_BUILD_STUB_OK'){
      throw 'Build stub did not complete'
     }
    } catch {
     if(!$shouldThrow -or $_.Exception.Message -cne 'PWM_BUILD_STUB_FAILURE'){throw}
     $caught=$true
    }
    if($caught -ne $shouldThrow){throw "Missing expected exception: $caseName"}
    if((Test-Path Env:MC_PWM) -ne $mcPresent -or $env:MC_PWM -cne $mcValue){
     throw "MC_PWM was not restored: $caseName"
    }
    if((Test-Path Env:AX03B3_TEST) -ne $testPresent -or $env:AX03B3_TEST -cne $testValue){
     throw "AX03B3_TEST was not restored: $caseName"
    }
    $results += [pscustomobject]@{case=$caseName;status='PASS'}
   }
  }
 }
} finally {
 # Restore the test caller too, including initially absent variables.
 foreach($name in @('MC_PWM','AX03B3_TEST')){
  if($savedEnvironment.Contains($name)){
   [Environment]::SetEnvironmentVariable($name,$savedEnvironment[$name],'Process')
  } else {Set-Item -LiteralPath "Env:$name" -Value $null}
 }
 Set-Location -LiteralPath $savedLocation.Path
}
[pscustomobject]@{
 status='PASS';cases=$results.Count;vivado='NOT_RUN';results=$results
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runPath 'summary.json') -Encoding UTF8
"PWM_BUILD_ENV_PASS cases=$($results.Count) vivado=NOT_RUN"

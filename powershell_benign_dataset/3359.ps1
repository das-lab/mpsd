













$excludedExtensions = @(".dll", ".zip", ".msi", ".exe")







function Get-Transcript 
{
   param([string] $path)
   return Get-Content $path |
   Select-String -InputObject {$_} -Pattern "^Start Time\s*:.*" -NotMatch |
   Select-String -InputObject {$_} -Pattern "^End Time\s*:.*" -NotMatch |
   Select-String -InputObject {$_} -Pattern "^Machine\s*:.*" -NotMatch |
   Select-String -InputObject {$_} -Pattern "^Username\s*:.*" -NotMatch |
   Select-String -InputObject {$_} -Pattern "^Transcript started, output file is.*" -NotMatch
}







function Get-LogFile
{
    param([string] $rootPath = ".")
    return [System.IO.Path]::Combine($rootPath, ([System.IO.Path]::GetRandomFileName()))
}











function Run-Test 
{
    param([scriptblock]$test, [string] $testName = $null, [string] $testScript = $null, [switch] $generate = $false)
    Test-Setup
    $transFile = $testName + ".log"
    if ($testName -eq $null) 
    {
      $transFile = Get-LogFile "."
    }
    if($testScript)
    {
        if ($generate)
        {
            Write-Log "[run-test]: generating script file $testScript"
            $transFile = $testScript
        }
        else
        {
            Write-Log "[run-test]: writing output to $transFile, using validation script $testScript"
        }
    }
    else
    {
         Write-Log "[run-test]: Running test without file comparison"
    }
        
    $oldPref = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    
    $success = $false;
    $ErrorActionPreference = $oldPref
    try 
    {
      &$test
      $success = $true;
    }
    finally 
    {
        Test-Cleanup
        $oldPref = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        
        $ErrorActionPreference = $oldPref
        if ($testScript)
        {
            if ($success -and -not $generate)
            {
                $result = Compare-Object (Get-Transcript $testScript) (Get-Transcript $transFile)
                if ($result -ne $null)
                {
                    throw "[run-test]: Test Failed " + (Out-String -InputObject $result) + ", Transcript at $transFile"
                }
            
            }
        }
        
        if ($success)
        {
            Write-Log "[run-test]: Test Passed"
        }
    }
    
}







function Write-Log
{
    [CmdletBinding()]
    param( [Object] [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$false)] $obj = "")
    PROCESS
    {
        $obj | Out-String | Write-Verbose
    }
}

function Check-SubscriptionMatch
{
    param([string] $baseSubscriptionName, [Microsoft.WindowsAzure.Commands.Utilities.Common.SubscriptionData] $checkedSubscription)
    Write-Log ("[CheckSubscriptionMatch]: base subscription: '$baseSubscriptionName', validating '" + ($checkedSubscription.SubscriptionName)+ "'")
    Format-Subscription $checkedSubscription | Write-Log
    if ($baseSubscriptionName -ne $checkedSubscription.SubscriptionName) 
    {
        throw ("[Check-SubscriptionMatch]: Subscription Match Failed '" + ($baseSubscriptionName) + "' != '" + ($checkedSubscription.SubscriptionName) + "'")
    }
    
    Write-Log ("CheckSubscriptionMatch]: subscription check succeeded.")
}









function Get-FullName
{
    param([string] $path)
    $pathObj = Get-Item $path
    return ($pathObj.FullName)
}







function Test-Setup
{
    $global:oldConfirmPreference = $global:ConfirmPreference
    $global:oldDebugPreference = $global:DebugPreference
    $global:oldErrorActionPreference = $global:ErrorActionPreference
    $global:oldFormatEnumerationLimit = $global:FormatEnumerationLimit
    $global:oldProgressPreference = $global:ProgressPreference
    $global:oldVerbosePreference = $global:VerbosePreference
    $global:oldWarningPreference = $global:WarningPreference
    $global:oldWhatIfPreference = $global:WhatIfPreference
    $global:ConfirmPreference = "None"
    $global:DebugPreference = "Continue"
    $global:ErrorActionPreference = "Stop"
    $global:FormatEnumerationLimit = 10000
    $global:ProgressPreference = "SilentlyContinue"
    $global:VerbosePreference = "Continue"
    $global:WarningPreference = "Continue"
    $global:WhatIfPreference = 0
}






function Test-Cleanup
{
     $global:ConfirmPreference = $global:oldConfirmPreference
     $global:DebugPreference = $global:oldDebugPreference
     $global:ErrorActionPreference = $global:oldErrorActionPreference
     $global:FormatEnumerationLimit = $global:oldFormatEnumerationLimit
     $global:ProgressPreference = $global:oldProgressPreference
     $global:VerbosePreference = $global:oldVerbosePreference
     $global:WarningPreference = $global:oldWarningPreference
     $global:WhatIfPreference = $global:oldWhatIfPreference
}








function Dump-Contents
{
    param([string] $rootPath = ".", [switch] $recurse = $false)
    if (-not ((Test-Path $rootPath) -eq $true))
    {
        throw "[dump-contents]: $rootPath does not exist"
    }
    
    foreach ($item in Get-ChildItem $rootPath)
    {
        Write-Log
        Write-Log "---------------------------"
        Write-Log $item.Name
        Write-Log "---------------------------"
        Write-Log
        if (!$item.PSIsContainer)
        {
           if (Test-BinaryFile $item)
           {
               Write-Log "---- binary data excluded ----"
           }
           else
           {
               Get-Content ($item.PSPath)
           }
        }
        elseif ($recurse)
        {
            Dump-Contents ($item.PSPath) -recurse
        }
    }
}

function Test-BinaryFile
{
    param ([System.IO.FileInfo] $file)
    ($excludedExtensions | Where-Object -FilterScript {$_ -eq $file.Extension}) -ne $null
}



function Remove-AllSubscriptions
{
    Get-AzureSubscription | Remove-AzureSubscription -Force
}


function Wait-Function
{
    param([ScriptBlock] $scriptBlock, [object] $breakCondition, [int] $timeout)

    if ($timeout -eq 0) { $timeout = 60 * 5 }
    $start = [DateTime]::Now
    $current = [DateTime]::Now
    $diff = $current - $start

    do
    {
        Wait-Seconds 5
        $current = [DateTime]::Now
        $diff = $current - $start
        $result = &$scriptBlock
    }
    while(($result -ne $breakCondition) -and ($diff.TotalSeconds -lt $timeout))

    if ($diff.TotalSeconds -ge $timeout)
    {
        Write-Warning "The script block '$scriptBlock' exceeded the timeout."
        
        exit
    }
}



function Wait-Seconds {
    param([int] $timeout)

    try {
        [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::Wait($timeout * 1000);
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            Start-Sleep -Seconds $timeout;
        } else {
            throw;
        }
    }
}



function Retry-Function
{
    param([ScriptBlock] $scriptBlock, [Object] $argument, [int] $maxTries, [int] $interval)

    if ($interval -eq 0) { $interval = 60  }
    
    $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $argument;
    $tries = 1;
    while(( $result -ne $true) -and ($tries -le $maxTries))
    {
        Wait-Seconds $interval
        $result = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $argument;
        $tries++;
    }
    
    return $result;
}


function getRandomItemName {
    param([string] $prefix)
    
    if ($prefix -eq $null -or $prefix -eq '') {
        $prefix = "ps";
    }

    $str = $prefix + (([guid]::NewGuid().ToString() -replace '-','')[0..9] -join '');
    return $str;
}

function getAssetName {
    param([string] $prefix)

    if ($prefix -eq $null -or $prefix -eq '') {
        $prefix = "ps";
    }

    $testName = getTestName
    
    try {
        $assetName = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::GetAssetName($testName, $prefix);
    } catch {
        if ($PSItem.Exception.Message -like '*Unable to find type*') {
            $assetName = getRandomItemName $prefix;
        } else {
            throw;
        }
    }

    return $assetName
}


function getTestName
{
    $stack = Get-PSCallStack
    $testName = $null
    foreach ($frame in $stack)
    {
        if ($frame.Command.StartsWith("Test-", "CurrentCultureIgnoreCase"))
        {
            $testName = $frame.Command
        }
    }

    return $testName
}


function getVariable
{
   param([string]$variableName)
   $testName = getTestName
   $result = $null
  if ([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables.ContainsKey($variableName))
  {
      $result = [Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Variables[$variableName]
  }

  return $result
}


function getSubscription
{
   return $(getVariable "SubscriptionId")
}


function getTestMode
{
   return $([Microsoft.Azure.Test.HttpRecorder.HttpMockServer]::Mode)
}


function createTestCredential
{
  param([string]$username, [string]$password)
  $secPasswd = ConvertTo-SecureString $password -AsPlainText -Force
  return $(New-Object System.Management.Automation.PSCredential ($username, $secPasswd))
}


function getTestCredentialFromString
{
  param([string] $connectionString)
  $parsedString = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::ParseConnectionString($connectionString)
  if (-not ($parsedString.ContainsKey([Microsoft.Azure.Test.TestEnvironment]::UserIdKey) -or ((-not ($parsedString.ContainsKey([Microsoft.Azure.Test.TestEnvironment]::AADPasswordKey))))))
  {
    throw "The connection string '$connectionString' must have a valid value, including username and password " +`
            "in the following format: SubscriptionId=<subscription>;UserName=<username>;Password=<password>"
  }
  return $(createTestCredential $parsedString[[Microsoft.Azure.Test.TestEnvironment]::UserIdKey] $parsedString[[Microsoft.Azure.Test.TestEnvironment]::AADPasswordKey])
}


function getSubscriptionFromString
{
  param([string] $connectionString)
  $parsedString = [Microsoft.Rest.ClientRuntime.Azure.TestFramework.TestUtilities]::ParseConnectionString($connectionString)
  if (-not ($parsedString.ContainsKey([Microsoft.Azure.Test.TestEnvironment]::SubscriptionIdKey)))
  {
    throw "The connection string '$connectionString' must have a valid value, including subscription " +`
            "in the following format: SubscriptionId=<subscription>;UserName=<username>;Password=<password>"
  }
  return $($parsedString[[Microsoft.Azure.Test.TestEnvironment]::SubscriptionIdKey])
}

function getCredentialFromEnvironment
{
   param([string]$testEnvironment)
   $credential = $null
   $testMode = getTestMode
   if ($testMode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecordMode]::Playback)
   {
       $environmentVariable = $null;
       if ([System.string]::Equals($testEnvironment, "rdfe", [System.StringComparison]::OrdinalIgnoreCase))
       {
           $environmentVariable = [Microsoft.Azure.Test.RDFETestEnvironmentFactory]::TestOrgIdAuthenticationKey
       }
       else
       {
           $environmentVariable = [Microsoft.Azure.Test.CSMTestEnvironmentFactory]::TestCSMOrgIdConnectionStringKey
       }

       $environmentValue = [System.Environment]::GetEnvironmentVariable($environmentVariable)
       if ([System.string]::IsNullOrEmpty($environmentValue))
       {
          throw "The environment variable '$environmentVariable' must have a valid value, including username and password " +`
            "in the following format: $environmentVariable=SubscriptionId=<subscription>;UserName=<username>;Password=<password>"
       }

       $credential = $(getTestCredentialFromString $environmentValue)
   }

   return $credential
}


function getSubscriptionFromEnvironment
{
   param([string]$testEnvironment)
   $subscription = $null
   $testMode = getTestMode
   if ($testMode -ne [Microsoft.Azure.Test.HttpRecorder.HttpRecordMode]::Playback)
   {
       $environmentVariable = $null;
       if ([System.string]::Equals($testEnvironment, "rdfe", [System.StringComparison]::OrdinalIgnoreCase))
       {
           $environmentVariable = [Microsoft.Azure.Test.RDFETestEnvironmentFactory]::TestOrgIdAuthenticationKey
       }
       else
       {
           $environmentVariable = [Microsoft.Azure.Test.CSMTestEnvironmentFactory]::TestCSMOrgIdConnectionStringKey
       }

       $environmentValue = [System.Environment]::GetEnvironmentVariable($environmentVariable)
       if ([System.string]::IsNullOrEmpty($environmentValue))
       {
          throw "The environment variable '$environmentVariable' must have a valid value, including subscription id" +`
            "in the following format: $environmentVariable=SubscriptionId=<subscription>;UserName=<username>;Password=<password>"
       }

       $subscription = $(getSubscriptionFromString $environmentValue)
   }
   else
   {
      $subscription = $(getSubscription)
   }

   return $subscription
}

function Get-Location
{
    param([string]$providerNamespace, [string]$resourceType, [string]$preferredLocation, [switch]$UseCanonical)
    $provider = Get-AzureRmResourceProvider -ProviderNamespace $providerNamespace
    $resourceTypes = $null
    if ( ( $provider.ResourceTypes -ne $null ) -and ( $provider.ResourceTypes.Count -gt 0 ) )
    {
        $nameFound = $provider.ResourceTypes[0]| Get-Member | Where-Object { $_.Name -eq "Name" }
        $resourceTypeNameFound = $provider.ResourceTypes[0]| Get-Member | Where-Object { $_.Name -eq "ResourceTypeName" }
        if ( $nameFound -ne $null )
        {
            $resourceTypes = $provider.ResourceTypes | Where-Object { $_.Name -eq $resourceType }
        }
        elseif ( $resourceTypeNameFound -ne $null )
        {
            $resourceTypes = $provider.ResourceTypes | Where-Object { $_.ResourceTypeName -eq $resourceType }
        }
        else
        {
            $resourceTypes = $provider.ResourceTypes | Where-Object { $_.ResourceType -eq $resourceType }
        }
    }
    $locations = $resourceTypes.Locations
    if($UseCanonical -and $locations -ne $null)
    {
        $locations = $locations | ForEach-Object { Normalize-Location $_ }
    }
    $location = $locations | Where-Object { $_ -eq $preferredLocation }
    if ($location -eq $null)
    {
        if ($locations.Count -ne 0)
        {
            return $locations[0]
        }
        else
        {
            $defaultLocation = "West US"
            if($UseCanonical)
            {
                $defaultLocation = "westus"
            }
            return $defaultLocation
        }
    }
    else
    {
        return $location
    }
}

function Normalize-Location
{
    param([string]$location)
    return $location.ToLower() -replace '[^a-z0-9]'
}

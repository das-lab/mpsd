













$global:createdKeys = @()
$global:createdSecrets = @()
$global:createdCertificates = @()
$global:createdManagedStorageAccounts = @()

$invocationPath = Split-Path $MyInvocation.MyCommand.Definition;


function Get-KeyVault([bool] $haspermission=$true)
{
    if ($global:testVault -ne "" -and $haspermission)
    {
        return $global:testVault
    }   
    elseif ($haspermission)
    {
        return 'azkmspsprodeus'    
    }
    else
    {
        return 'azkmspsnopermprodeus'
    }
}


function Get-KeyName([string]$suffix)
{
	if($suffix -ne '*'){
		 $suffix += Get-Random
	}

    return 'pshtk-' + $global:testns+ '-' + $suffix
}


function Get-SecretName([string]$suffix)
{
	if($suffix -ne '*'){
		 $suffix += Get-Random
	}

    return 'pshts-' + $global:testns + '-' + $suffix
}


function Get-CertificateName([string]$suffix)
{
    return 'pshtc-' + $global:testns + '-' + $suffix
}


function Get-ManagedStorageAccountName([string]$suffix)
{
    return 'pshtmsa' + $global:testns + $suffix
}


function Get-ManagedStorageSasDefinitionName([string]$suffix)
{
    return 'pshtmsas' + $global:testns + $suffix
}


function Get-KeyVaultManagedStorageResourceId
{
    return $global:storageResourceId
}


function Get-ImportKeyFile([string]$filesuffix, [bool] $exists=$true)
{
    if ($exists)
    {
        $file = "$filesuffix"+"test.$filesuffix"
    }
    else
    {
        $file = "notexist" + ".$filesuffix"
    }

    if ($global:testEnv -eq 'BVT')
    {       
        return Join-Path $invocationPath "bvtdata\$file"        
    }
    else
    {
        return Join-Path $invocationPath "proddata\$file"
    }
}


function Get-ImportKeyFile1024([string]$filesuffix, [bool] $exists=$true)
{
    if ($exists)
    {
        $file = "$filesuffix"+"test1024.$filesuffix"
    }
    else
    {
        $file = "notexist" + ".$filesuffix"
    }

    if ($global:testEnv -eq 'BVT')
    {       
        return Join-Path $invocationPath "bvtdata\$file"        
    }
    else
    {
        return Join-Path $invocationPath "proddata\$file"
    }
}



function Get-FilePathFromCommonData([string]$fileName)
{
    return Join-Path $invocationPath "commondata\$fileName"
}


function Cleanup-LogFiles([string]$rootfolder)
{
    Write-Host "Cleaning up log files from $rootfolder..."
    
    Get-ChildItem –Path $rootfolder -Include *.debug_log -Recurse |
        where {$_.mode -match "a"} |
        Remove-Item -Force     
}


function Move-Log([string]$rootfolder)
{    
    $logfolder = Join-Path $rootfolder ("$global:testEnv"+"$global:testns"+"log")
    if (Test-Path $logfolder)
    {
        Cleanup-LogFiles $logfolder
    }
    else
    {
        New-Item $logfolder -type directory -force
    }

    Get-ChildItem –Path $rootfolder -Include *.debug_log -Recurse | Move-Item -Destination $logfolder
}



function Cleanup-OldCertificates
{
    Write-Host "Cleaning up old certificates..."

    $keyVault = Get-KeyVault
    $certificatePattern = Get-CertificateName '*'
    Get-AzKeyVaultCertificate $keyVault |
        Where-Object {$_.Name -like $certificatePattern} |
        Remove-AzKeyVaultCertificate -Name $_.Name -VaultName $_.VaultName -Force -Confirm:$false

    if($global:softDeleteEnabled -eq $true) 
    {
      Get-AzKeyVaultCertificate -VaultName $keyVault -InRemovedState |
      Where-Object {$_.Name -like $certificatePattern} | %{
        Remove-AzKeyVaultCertificate -Name $_.Name -VaultName $_.VaultName -InRemovedState -Force -Confirm:$false
        Wait-Seconds 5;
      }
    }
}


function Cleanup-OldKeys
{
    Write-Host "Cleaning up old keys..."

    $keyVault = Get-KeyVault
    $keyPattern = Get-KeyName '*'
    Get-AzKeyVaultKey $keyVault |
        Where-Object {$_.Name -like $keyPattern} |
		Cleanup-Key $_.Name

	if($global:softDeleteEnabled -eq $true) 
	{
		Get-AzKeyVaultKey $keyVault -InRemovedState |
			Where-Object {$_.Name -like $keyPattern} | %{
				Remove-AzKeyVaultKey -Name $_.Name -VaultName $_.VaultName -InRemovedState -Force -Confirm:$false
				Wait-Seconds 5;
			}
	}
}


function Cleanup-OldSecrets
{
    Write-Host "Cleaning up old secrets..."

    $keyVault = Get-KeyVault
    $secretPattern = Get-SecretName '*'
    Get-AzKeyVaultSecret $keyVault |
        Where-Object {$_.Name -like $secretPattern} | 
		Cleanup-Secret $_.Name
	
	if($global:softDeleteEnabled -eq $true) 
	{
		Get-AzKeyVaultSecret $keyVault -InRemovedState |
			Where-Object {$_.Name -like $secretPattern} |  %{
				Remove-AzKeyVaultSecret -Name $_.Name -VaultName $_.VaultName -Force -Confirm:$false -InRemovedState
				Wait-Seconds 5
			}
	}
}


function Cleanup-OldManagedStorageAccounts
{
    Write-Host "Cleaning up old managed storage accounts..."

    $keyVault = Get-KeyVault
    $managedStorageAccountPattern = Get-ManagedStorageAccountName '*'
    Get-AzKeyVaultManagedStorageAccount $keyVault |
        Where-Object {$_.AccountName -like $managedStorageAccountPattern} |
        Remove-AzKeyVaultManagedStorageAccount -Force -Confirm:$false
}


function Initialize-CertificateTest
{
    $keyVault = Get-KeyVault
    $certificatePattern = Get-CertificateName '*'
    Get-AzKeyVaultCertificate $keyVault  | Where-Object {$_.Name -like $certificatePattern}  | Remove-AzKeyVaultCertificate -Force
}


function Initialize-ManagedStorageAccountTest
{
    $keyVault = Get-KeyVault
    $managedStorageAccountPattern = Get-ManagedStorageAccountName '*'
    Get-AzKeyVaultManagedStorageAccount $keyVault  | Where-Object {$_.AccountName -like $managedStorageAccountPattern}  | Remove-AzKeyVaultManagedStorageAccount -Force
}


function Cleanup-SingleKeyTest
{
    $global:createdKeys | % {
       if ($_ -ne $null)
       {
         Cleanup-Key $_
      }
    }

    $global:createdKeys.Clear()    
}

function Cleanup-Key ([string]$keyName)
{
  $oldPref = $ErrorActionPreference	 
  $ErrorActionPreference = "Stop"
  try
  {
    $keyVault = Get-KeyVault
    Write-Debug "Removing key with name $_ in vault $keyVault"
    $catch = Remove-AzKeyVaultKey $keyVault $keyName -Force -Confirm:$false
    if($global:softDeleteEnabled -eq $true)
    {
      Wait-ForDeletedKey $keyVault $keyName
      Remove-AzKeyVaultKey $keyVault $keyName -Force -Confirm:$false -InRemovedState
    }
  }
  catch {
  
  }
  finally 
  {
    $ErrorActionPreference = $oldPref	 
  }
}

function Cleanup-Secret ([string]$secretName)
{
  $oldPref = $ErrorActionPreference	 
  $ErrorActionPreference = "Stop"
  try
  {
    $keyVault = Get-KeyVault
    Write-Debug "Removing secret with name $_ in vault $keyVault"
    $catch = Remove-AzKeyVaultSecret $keyVault $secretName -Force -Confirm:$false
    if($global:softDeleteEnabled -eq $true)
    {
      Wait-ForDeletedSecret $keyVault $secretName
      Remove-AzKeyVaultSecret $keyVault $secretName -Force -Confirm:$false -InRemovedState
    }
  }
  catch {
  }
  finally 
  {
    $ErrorActionPreference = $oldPref
  }
}


function Cleanup-SingleSecretTest
{
    $global:createdSecrets | % {
       if ($_ -ne $null)
       {
         Cleanup-Secret $_
      }
    }

    $global:createdSecrets.Clear()    
}


function Cleanup-SingleCertificateTest
{
    $global:createdCertificates | % {
       if ($_ -ne $null)
       {
         try
         {
            $keyVault = Get-KeyVault
            Write-Debug "Removing certificate with name $_ in vault $keyVault"
            $catch = Remove-AzKeyVaultCertificate $keyVault $_ -Force -Confirm:$false
		    if($global:softDeleteEnabled -eq $true)
		    {
			    Wait-ForDeletedCertificate $keyVault $_
			    Remove-AzKeyVaultCertificate $keyVault $_ -Force -Confirm:$false -InRemovedState
		    }
         }
         catch 
         {
         }
      }
    }

    $global:createdCertificates.Clear()    
}


function Wait-ForDeletedKey ([string] $vault, [string] $keyName)
{
	$key = $null
	do {
		$oldPref = $ErrorActionPreference	 
		$ErrorActionPreference = "Stop"
		try
		{
			$key = Get-AzKeyVaultKey -VaultName $vault -Name $keyName -InRemovedState
		}
		catch
		{
			
			$key = $null
			Write-Host "Sleeping for 5 seconds to wait for deleted key $keyName"
			Wait-Seconds 5
		}
		finally {
			$ErrorActionPreference = $oldPref
		}
	} while($key -eq $null)

	return $key
}


function Wait-ForDeletedSecret ([string] $vault, [string] $secretName)
{
	$secret = $null
	do {
		try
		{
			$secret = Get-AzKeyVaultSecret -VaultName $vault -Name $secretName -InRemovedState
		}
		catch
		{
			
			$secret = $null
			Write-Host "Sleeping for 5 seconds to wait for deleted key $secretName"
			Wait-Seconds 5
		}
	} while($secret -ne $null)

	return $secret
}


function Wait-ForDeletedCertificate ([string] $vault, [string] $certName)
{
	$cert = $null
	do {
		try
		{
			$cert = Get-AzKeyVaultCertificate -VaultName $vault -Name $certName -InRemovedState
		}
		catch
		{
			
			$cert = $null
			Write-Host "Sleeping for 5 seconds to wait for deleted certificate $certName"
			Wait-Seconds 5
		}
	} while($cert -ne $null)

	return $cert
}


function Cleanup-SingleManagedStorageAccountTest
{
    $global:createdManagedStorageAccounts | % {
       if ($_ -ne $null)
       {
         try
         {
            $keyVault = Get-KeyVault
            Write-Debug "Removing managed storage account with name $_ in vault $keyVault"
            $catch = Remove-AzKeyVaultManagedStorageAccount $keyVault $_ -Force -Confirm:$false
         }
         catch 
         {
         }
      }
    }

    $global:createdManagedStorageAccounts.Clear()
}


function Run-KeyTest ([ScriptBlock] $test, [string] $testName)
{   
   try 
   {
     Run-Test $test $testName *>> "$testName.debug_log"
   }
   finally 
   {
     Cleanup-SingleKeyTest *>> "$testName.debug_log"
   }
}

function Run-SecretTest ([ScriptBlock] $test, [string] $testName)
{   
   try 
   {
     Run-Test $test $testName *>> "$testName.debug_log"
   }
   finally 
   {
     Cleanup-SingleSecretTest *>> "$testName.debug_log"
   }
}

function Run-CertificateTest ([ScriptBlock] $test, [string] $testName)
{   
   try 
   {
     Run-Test $test $testName *>> "$testName.debug_log"
   }
   finally 
   {
     Cleanup-SingleCertificateTest *>> "$testName.debug_log"
   }
}

function Run-ManagedStorageAccountTest ([ScriptBlock] $test, [string] $testName)
{   
   try 
   {
     Run-Test $test $testName *>> "$testName.debug_log"
   }
   finally 
   {
     Cleanup-SingleManagedStorageAccountTest *>> "$testName.debug_log"
   }
}

function Run-VaultTest ([ScriptBlock] $test, [string] $testName)
{   
   try 
   {
     Run-Test $test $testName *>> "$testName.debug_log"
   }
   finally 
   {
     
   }
}

function Write-FileReport
{
    $fileName = "$global:testEnv"+"$global:testns"+"Summary.debug_log"	
    Get-TestRunReport *>> $fileName
}


function Get-TestRunReport
{

    Write-Output "PASSED TEST Count=$global:passedCount"
    Write-Output "Total TEST Count=$global:totalCount"
    Write-Output "Start Time=$global:startTime"
    Write-Output "End Time=$global:endTime"
    $elapsed=$global:endTime - $global:startTime
    Write-Output "Elapsed=$elapsed"
   
    Write-Output "Passed TEST`tExecutionTime"
    $global:passedTests | % { $extime=$global:times[$_]; Write-Output $_`t$extime }
    Write-Output "Failed TEST lists"
    $global:failedTests | % { $extime=$global:times[$_]; Write-Output $_`t$extime }	
}

function Write-ConsoleReport
{
    Write-Host
    Write-Host -ForegroundColor Green "$global:passedCount / $global:totalCount Key Vault Tests Pass"
    Write-Host -ForegroundColor Green "============"
    Write-Host -ForegroundColor Green "PASSED TESTS"
    Write-Host -ForegroundColor Green "============"
    $global:passedTests | % { Write-Host -ForegroundColor Green "PASSED "$_": "($global:times[$_]).ToString()}
    Write-Host -ForegroundColor Green "============"
    Write-Host
    Write-Host -ForegroundColor Red "============"
    Write-Host -ForegroundColor Red "FAILED TESTS"
    Write-Host -ForegroundColor Red "============"
    $global:failedTests | % { Write-Host -ForegroundColor Red "FAILED "$_": "($global:times[$_]).ToString()}
    Write-Host -ForegroundColor Red "============"
    Write-Host
    Write-Host -ForegroundColor Green "======="
    Write-Host -ForegroundColor Green "TIMES"
    Write-Host -ForegroundColor Green "======="
    Write-Host
    Write-Host -ForegroundColor Green "Start Time: $global:startTime"
    Write-Host -ForegroundColor Green "End Time: $global:endTime"
    Write-Host -ForegroundColor Green "Elapsed: "($global:endTime - $global:startTime).ToString()	
}

function Equal-DateTime($left, $right)
{   
    if ($left -eq $null -and $right -eq $null)
    {        
        return $true
    }
    if ($left -eq $null -or $right -eq $null)
    {
        return $false
    }
    
    return (($left - $right).Duration() -le $delta)
}

function Equal-Hashtable($left, $right)
{
    if ((EmptyOrNullHashtable $left) -and (-Not (EmptyOrNullHashtable $right)))
    {
        return $false
    }  
    if ((EmptyOrNullHashtable $right) -and (-Not (EmptyOrNullHashtable $left)))
    {
        return $false
    } 
    if ($right.Count -ne $left.Count)
    {
        return $false
    }
    
    return $true
}

function EmptyOrNullHashtable($hashtable)
{
    return ($hashtable -eq $null -or $hashtable.Count -eq 0)
}

function Equal-OperationList($left, $right)
{   
    if ($left -eq $null -and $right -eq $null)
    {        
        return $true
    }
    if ($left -eq $null -or $right -eq $null)
    {
        return $false
    }

    $diff = Compare-Object -ReferenceObject $left -DifferenceObject $right -PassThru
    
    return (-not $diff)
}

function Equal-String($left, $right)
{
    if (([string]::IsNullOrEmpty($left)) -and ([string]::IsNullOrEmpty($right)))
    {
        return $true
    }
    if (([string]::IsNullOrEmpty($left)) -or ([string]::IsNullOrEmpty($right)))
    {
        return $false
    }    
    
    return $left.Equals($right)
}
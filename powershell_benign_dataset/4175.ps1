
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$DataFile,
	[string]
	$LogFile,
	[int]
	$ProcessDelay
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Import-DataFile {

	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	
	$RelativePath = Get-RelativePath
	
	$File = $RelativePath + $DataFile
	
	$FileData = Get-Content -Path $File -Force
	
	$Fields = ($FileData[0]).Split(",")
	$ImportedRecords = @()
	foreach ($Record in $FileData) {
		If ($Record -notlike "*extensionattribute*") {
			$SplitRecord = $Record.Split(",")
			$objRecord = New-Object System.Management.Automation.PSObject
			for ($i = 0; $i -lt $Fields.Length; $i++) {
				$objRecord | Add-Member -type NoteProperty -Name $Fields[$i] -Value $SplitRecord[$i]
			}
			$ImportedRecords += $objRecord
		}
	}
	Return $ImportedRecords
}

function New-Logfile {

	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$Logs = $RelativePath + $LogFile
	If ((Test-Path $Logs) -eq $true) {
		$Output = "Deleting old log file....."
		Remove-Item -Path $Logs -Force | Out-Null
		If ((Test-Path $Logs) -eq $false) {
			$Output += "Success" + "`n"
		} else {
			$Output += "Failed" + "`n"
		}
	}
	If (($LogFile -ne "") -and ($LogFile -ne $null)) {
		$Output += "Creating new log file....."
		New-Item -Path $Logs -ItemType File -Force | Out-Null
		If ((Test-Path $Logs) -eq $true) {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	}
}

function Write-ExtensionAttributes {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][object]
		$Records
	)
	
	
	$Fields = $Records | Get-Member
	
	$Fields = ($Fields | Where-Object { (($_.MemberType -eq "NoteProperty") -and ($_.Name -like "*extensionattribute*")) }).name
	for ($i = 0; $i -lt @($Records).Count; $i++) {
		
		$User = Get-ADUser $Records[$i].Username -Properties *
		$Output += "User " + ($i+1) + " of " + @($Records).Count + "`n"
		$Output += "Username: " + $Records[$i].Username + "`n"
		foreach ($Field in $Fields) {
			$Output += $Field + ": " + $Records[$i].$Field + "`n"
			If ((($Records[$i].$Field -eq "Clear") -or ($Records[$i].$Field -eq "") -or ($Records[$i].$Field -eq $null)) -and ($Records[$i].$Field -ne "NO CLEAR")) {
				$Output += "Clearing " + $Field + "....."
				Set-ADUser -Identity $Records[$i].Username -Clear $Field
				
				$Test = Get-ADUser $Records[$i].Username -Properties * | select $Field
				
				if ($Test.$Field -eq $null) {
					$Output += "Success" + "`n"
				} else {
					$Output += "Failed" + "`n"
				}
			} elseif ($Records[$i].$Field -ne "NO CLEAR") {
				$User.$Field = $Records[$i].$Field
				$Output += "Setting " + $Field + "....."
				
				Set-ADUser -Instance $User
				
				$Test = Get-ADUser $Records[$i].Username -Properties * | select $Field
				
				if ($Test.$Field -eq $Records[$i].$Field) {
					$Output += "Success" + "`n"
				} else {
					$Output += "Failed" + "`n"
				}
			}
		}
		Write-Output $Output
		
		If (($LogFile -ne "") -and ($LogFile -ne $null)) {
			
			$RelativePath = Get-RelativePath
			
			$Logs = $RelativePath + $LogFile
			
			Add-Content -Value $Output -Path $Logs -Encoding UTF8 -Force
		}
		$Output = $null
		If (($ProcessDelay -ne $null) -and ($ProcessDelay -ne "")) {
			Start-Sleep -Seconds $ProcessDelay
		}
		cls
	}
}

Import-Module -Name ActiveDirectory

New-Logfile

$Records = Import-DataFile

Write-ExtensionAttributes -Records $Records

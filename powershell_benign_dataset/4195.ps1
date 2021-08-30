
[CmdletBinding()]
param
(
	[string]
	$MemberExclusionsFile = 'MemberExclusions.txt',
	[switch]
	$OutputFile,
	[string]
	$OutputFileLocation = '',
	[switch]
	$SCCMReporting,
	[string]
	$SystemExclusionsFile = 'SystemExclusions.txt'
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-SCCMHardwareInventory {

	
	[CmdletBinding()]
	param ()
	
	$ComputerName = $env:COMPUTERNAME
	$SMSCli = [wmiclass] "\\$ComputerName\root\ccm:SMS_Client"
	$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}") | Out-Null
}

function New-WMIClass {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -ne $null) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Domain", [System.Management.CimType]::String, $false)
	$newClass.Properties["Domain"].Qualifiers.Add("key", $true)
	$newClass.Properties["Domain"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("User", [System.Management.CimType]::String, $false)
	$newClass.Properties["User"].Qualifiers.Add("key", $false)
	$newClass.Properties["User"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][array]
		$LocalAdministrators,
		[string]
		$Class
	)
	
	foreach ($LocalAdministrator in $LocalAdministrators) {
		$Output = "Writing" + [char]32 +$LocalAdministrator.User + [char]32 + "instance to" + [char]32 + $Class + [char]32 + "class....."
		$Return = Set-WmiInstance -Class $Class -Arguments @{ Domain = $LocalAdministrator.Domain; User = $LocalAdministrator.User }
		If ($Return -like "*" + $LocalAdministrator.User + "*") {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	}
}

cls

$RelativePath = Get-RelativePath

$ComputerName = $Env:COMPUTERNAME

$File = $RelativePath + $SystemExclusionsFile
$SystemExclusions = Get-Content $File
If ($SystemExclusions -notcontains $Env:COMPUTERNAME) {
	
	$File = $RelativePath + $MemberExclusionsFile
	$MemberExclusions = Get-Content $File
	
	$Members = net localgroup administrators | Where-Object { $_ -AND $_ -notmatch "command completed successfully" } | select -skip 4 | Where-Object { $MemberExclusions -notcontains $_ }
	$LocalAdmins = @()
	foreach ($Member in $Members) {
		
		$Admin = New-Object -TypeName System.Management.Automation.PSObject
		$Member = $Member.Split("\")
		If ($Member.length -gt 1) {
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name Domain -Value $Member[0].Trim()
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name User -Value $Member[1].Trim()
		} else {
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name Domain -Value ""
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name User -Value $Member.Trim()
		}
		$LocalAdmins += $Admin
	}
}

If ($SCCMReporting.IsPresent) {
	New-WMIClass -Class "Local_Administrators"
	New-WMIInstance -Class "Local_Administrators" -LocalAdministrators $LocalAdmins
	
	Invoke-SCCMHardwareInventory
}
If ($OutputFile.IsPresent) {
	If ($OutputFileLocation[$OutputFileLocation.Length - 1] -ne "\") {
		$File = $OutputFileLocation + "\" + $ComputerName + ".log"
	} else {
		$File = $OutputFileLocation + $ComputerName + ".log"
	}
	
	$Output = "Deleting $ComputerName.log....."
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	If ((Test-Path $File) -eq $false) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
	$Output = "Writing local admins to $ComputerName.log....."
	$LocalAdmins | Out-File $File
	If ((Test-Path $File) -eq $true) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

$LocalAdmins

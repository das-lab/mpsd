
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$SiteCode,
	[ValidateNotNullOrEmpty()][string]$SCCMModule
)
function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

Clear-Host
Import-Module DnsClient
Import-Module ActiveDirectory
Import-Module -Name $SCCMModule

If ($SiteCode[$SiteCode.Length - 1] -ne ":") {
	$SiteCode = $SiteCode + ":"
}

$Location = (get-location).Path.Split("\")[0]

Set-Location $SiteCode

Clear-Host
$RetrievalOutput = "Retrieving list of systems from SCCM....."
$Systems = Get-CMDevice -CollectionName "All Systems" | Where-Object { $_.Name -notlike "*Unknown Computer*" }
Clear-Host
If ($Systems -ne $null) {
	$RetrievalOutput += "Success"
} else {
	$RetrievalOutput += "Failed"
}
Write-Output $RetrievalOutput

$Report = @()
$Count = 1
foreach ($System in $Systems) {
	Clear-Host
	$ProcessingOutput = "Processing $Count of " + $Systems.Count + " systems"
	$SystemInfoOutput = "System Name: " + $System.Name
	Write-Output $RetrievalOutput
	Write-Output $ProcessingOutput
	Write-Output $SystemInfoOutput
	
	$SCCMSystemInfo = $Systems | Where-Object { $_.Name -eq $System.Name }
	
	Try {
		$LLTS = [datetime]::FromFileTime((get-adcomputer $System.Name -properties LastLogonTimeStamp -ErrorAction Stop).LastLogonTimeStamp).ToString('d MMMM yyyy')
	} Catch {
		$Output = $System.Name + " is not in active directory"
		Write-Output $Output
	}
	
	$Pingable = Test-Connection -ComputerName $System.Name -Count 2 -Quiet
	
	Try {
		$IPAddress = (Resolve-DnsName -Name $System.Name -ErrorAction Stop).IPAddress
	} Catch {
		$Output = $System.Name + " IP address cannot be resolved"
		Write-Output $Output
	}
	$Object = New-Object -TypeName System.Management.Automation.PSObject
	$Object | Add-Member -MemberType NoteProperty -Name Name -Value $System.Name
	$Object | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
	$Object | Add-Member -MemberType NoteProperty -Name ADLastLogon -Value $LLTS
	$Object | Add-Member -MemberType NoteProperty -Name Pingable -Value $Pingable
	$Object | Add-Member -MemberType NoteProperty -Name SCCMClient -Value $SCCMSystemInfo.IsClient
	$Object | Add-Member -MemberType NoteProperty -Name SCCMActive -Value $SCCMSystemInfo.IsActive
	$Object | Add-Member -MemberType NoteProperty -Name SCCMLastActiveTime -Value $SCCMSystemInfo.LastActiveTime
	$Report += $Object
	
	If ($IPAddress) {
		Remove-Variable -Name IPAddress -Force
	}
	If ($LLTS) {
		Remove-Variable -Name LLTS -Force
	}
	If ($Pingable) {
		Remove-Variable -Name Pingable -Force
	}
	If ($SCCMInfo) {
		Remove-Variable -Name SCCMInfo -Force
	}
	$Count++
}

Set-Location $Location
Clear-Host

$Report = $Report | Sort-Object -Property Name

$RelativePath = Get-RelativePath

$File = $RelativePath + "SCCMReport.csv"

If ((Test-Path $File) -eq $true) {
	Remove-Item -Path $File -Force
}

$Report | Export-Csv -Path $File -Encoding UTF8 -Force

$Report | Format-Table

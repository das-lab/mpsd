
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$LogFile,
	[switch]
	$Cached,
	[switch]
	$Online,
	[switch]
	$Full,
	[string]
	$OutputFile
)

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-AccountInfo {

	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	$RelativePath = Get-RelativePath
	$Logs = Get-Content $RelativePath$LogFile
	$Systems = @()
	foreach ($Log in $Logs) {
		$System = New-Object System.Management.Automation.PSObject
		$SplitLog = $Log.split(",")
		$Username = ((($SplitLog | Where-Object { $_ -like "*cn=*" }).split("/") | Where-Object { ($_ -like "*cn=*") -and ($_ -notcontains "cn=Recipients") }).split("="))[1]
		$Mode = $SplitLog | Where-Object { ($_ -contains "Classic") -or ($_ -contains "Cached") }
		If ($Mode -eq "Classic") {
			$Mode = "Online"
		}
		$System | Add-Member -type NoteProperty -Name Username -Value $Username
		$System | Add-Member -type NoteProperty -Name Mode -Value $Mode
		If ($Systems.Username -notcontains $Username) {
			$Systems += $System
		}
	}
	$Systems = $Systems | Sort-Object
	Return $Systems
}

$Logs = Get-AccountInfo
if ($Cached.IsPresent) {
	$Logs = $Logs | Where-Object { $_.Mode -eq "Cached" } | Sort-Object Username
	$Logs | Format-Table
}
if ($Online.IsPresent) {
	$Logs = $Logs | Where-Object { ($_.Mode -eq "Online") } | Sort-Object Username
	$Logs | Format-Table
}
if ($Full.IsPresent) {
	$Logs | Sort-Object Username
}
if (($OutputFile -ne $null) -and ($OutputFile -ne "")) {
	$RelativePath = Get-RelativePath
	$Logs | Sort-Object Username | Export-Csv $RelativePath$OutputFile -NoTypeInformation
}

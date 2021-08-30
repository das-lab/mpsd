
[CmdletBinding()]
param (
	[Parameter(Mandatory,
		ValueFromPipeline,
		ValueFromPipelineByPropertyName)]
	[ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1})]
	[string]$Computername,
	[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
	[string]$SiteServer = 'CONFIGMANAGER'
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
}

process {
	try {
		
		if (!$env:SMS_ADMIN_UI_PATH -or !(Test-Path "$($env:SMS_ADMIN_UI_PATH)\CmRcViewer.exe")) {
			throw "Unable to find the SCCM remote tools exe.  Is the console installed?"
		} else {
			$RemoteToolsFilePath = "$($env:SMS_ADMIN_UI_PATH)\CmRcViewer.exe"
		}
		
		& $RemoteToolsFilePath $Computername "\\$SiteServer"
		
	} catch {
		Write-Error $_.Exception.Message
	}
}
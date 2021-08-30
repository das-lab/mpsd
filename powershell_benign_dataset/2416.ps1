


[CmdletBinding()]
param (
	[Parameter(Mandatory = $False,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $True)]
	[string]$SiteCode = 'UHP',
	[Parameter(Mandatory = $False,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $True)]
	[string]$SiteServer = 'CONFIGMANAGER',
	[Parameter(Mandatory = $True,
			   ValueFromPipeline = $True,
			   ValueFromPipelineByPropertyName = $True)]
	[string]$CollectionName
)

begin {
	try {
		if ([Environment]::Is64BitProcess) {
			
			throw 'This script must be run in a x86 shell.'
		}
		$ConfigMgrModule = "$($env:SMS_ADMIN_UI_PATH | Split-Path -Parent)\ConfigurationManager.psd1"
		if (!(Test-Path $ConfigMgrModule)) {
			throw 'Configuration Manager module not found in admin console path'
		}
		Import-Module $ConfigMgrModule
		
		$BeforeLocation = (Get-Location).Path
	} catch {
		Write-Error $_.Exception.Message	
	}
}

process {
	try {
		Set-Location "$SiteCode`:"
		$CommonWmiParams = @{
			'ComputerName' = $SiteServer
			'Namespace' = "root\sms\site_$SiteCode"
		}
		
		
		
		$CollectionId = Get-WmiObject @CommonWmiParams -Query "SELECT CollectionID FROM SMS_Collection WHERE Name = '$CollectionName'" | select -ExpandProperty CollectionID
		if (!$CollectionId) {
			throw "No collection found with the name $CollectionName"
		}
				
		
		$CollectionMembers = Get-WmiObject @CommonWmiParams -Query "SELECT Name FROM SMS_CollectionMember_a WHERE CollectionID = '$CollectionId'" | Select -ExpandProperty Name
		
		if (!$CollectionMembers) {
			Write-Warning 'No collection members found in collection'
		} else {
			@($CollectionMembers).foreach({
				Remove-CMDeviceCollectionDirectMembershipRule -CollectionID $CollectionID -ResourceName $_ -force
			})
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}

end {
	Set-Location $BeforeLocation
}
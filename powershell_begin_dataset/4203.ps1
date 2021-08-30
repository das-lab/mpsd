
param
(
	[ValidateNotNullOrEmpty()]$MSPFileName = 'accessde-en-us.msp',
	[ValidateNotNullOrEmpty()]$MSPProperty = 'KBArticle Number'
)

function Get-MSPFileInfo {
	param
	(
		[Parameter(Mandatory = $true)][IO.FileInfo]$Path,
		[Parameter(Mandatory = $true)][ValidateSet('Classification', 'Description', 'DisplayName', 'KBArticle Number', 'ManufacturerName', 'ReleaseVersion', 'TargetProductName')][string]$Property
	)
	
	try {
		
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 32))
		
		$Query = "SELECT Value FROM MsiPatchMetadata WHERE Property = '$($Property)'"
		
		$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		
		$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
		
		$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
		return $Value
	} catch {
		Write-Output $_.Exception.Message
	}
}

Get-MSPFileInfo -Path $MSPFileName -Property $MSPProperty



[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

param (
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string[]]$FolderPath,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[int]$DaysOld,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateLength(1, 3)]
	[string]$FileExtension
)

$Now = Get-Date

$gciParams = @{
	'Recurse' = $true
	'File' = $true
}

if ($PSBoundParameters.ContainsKey('FileExtension')) {
	$gciParams.Filter = "Extension -eq $FileExtension"
}

$LastWrite = $Now.AddDays(-$DaysOld)

foreach ($path in $FolderPath)
{
	$gciParams.Path = $path
	((Get-ChildItem @gciParams).Where{ $_.LastWriteTime -le $LastWrite }).foreach{
		if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove'))
		{
			Remove-Item -Path $_.FullName -Force
		}
	}
}
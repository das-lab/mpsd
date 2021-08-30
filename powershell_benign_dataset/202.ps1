function Get-PSObjectEmptyOrNullProperty
{

	PARAM (
		$PSObject)
	PROCESS
	{
		$PsObject.psobject.Properties |
		Where-Object { -not $_.value }
	}
}

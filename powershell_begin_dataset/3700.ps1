














function Assert-NotNullOrEmpty
{
	param([string]$value)

	Assert-False { [string]::IsNullOrEmpty($value) }
}

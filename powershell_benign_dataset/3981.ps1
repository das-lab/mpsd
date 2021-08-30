














function Assert-NotNullOrEmpty
{
	param([string]$value)

	Assert-False { [string]::IsNullOrEmpty($value) }
}


function Assert-IsInstance
{
	param([object] $obj, [Type] $type)

	Assert-AreEqual $obj.GetType() $type
}


function Assert-PropertiesCount
{
	param([PSCustomObject] $obj, [int] $count)

	$properties = $obj.PSObject.Properties
	Assert-AreEqual $([System.Linq.Enumerable]::ToArray($properties).Count) $count
}
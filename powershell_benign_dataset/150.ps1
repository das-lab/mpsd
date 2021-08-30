function Remove-PSObjectProperty
{

	PARAM (
		$PSObject,

		[String[]]$Property)
	PROCESS
	{
		Foreach ($item in $Property)
		{
			$PSObject.psobject.Properties.Remove("$item")
		}
	}
}
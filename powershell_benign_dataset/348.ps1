function Register-PSFConfigSchema
{

	[CmdletBinding()]
	Param (
		[string]
		$Name,
		
		[ScriptBlock]
		$Schema
	)
	
	process
	{
		[PSFramework.Configuration.ConfigurationHost]::Schemata[$Name] = $Schema
	}
}
function Get-FunctionDefaultParameter
{
	
	[CmdletBinding()]
	[OutputType([hashtable])]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FunctionName	
	)
	try
	{
		$ast = (Get-Command $FunctionName).ScriptBlock.Ast
		
		$select = @{ n = 'Name'; e = { $_.Name.VariablePath.UserPath } },
		@{ n = 'Value'; e = { $_.DefaultValue.Extent.Text -replace "`"|'" } }
		
		$ht = @{}
		@($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true) | Where-Object { $_.DefaultValue } | Select-Object $select).foreach({
			$ht[$_.Name] = $_.Value	
			})
		$ht
		
	}
	catch
	{
		Write-Error -Message $_.Exception.Message
	}
}
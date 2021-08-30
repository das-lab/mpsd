function Get-ScriptAlias
{

	[CmdletBinding()]
	PARAM
	(
		[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateScript({ Test-Path -Path $_ })]
		[Alias("FullName")]
		[System.String[]]$Path
	)
	PROCESS
	{
		FOREACH ($File in $Path)
		{
			TRY
			{
				
				$ScriptContent = (Get-Content $File -Delimiter $([char]0))

				
				$AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
				ParseInput($ScriptContent, [ref]$null, [ref]$null)

				
				$AbstractSyntaxTree.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
				ForEach-Object -Process {
					$Command = $_.CommandElements[0]
					if ($Alias = Get-Alias | Where-Object { $_.Name -eq $Command })
					{

						
						[PSCustomObject]@{
							File = $File
							Alias = $Alias.Name
							Definition = $Alias.Definition
							StartLineNumber = $Command.Extent.StartLineNumber
							EndLineNumber = $Command.Extent.EndLineNumber
							StartColumnNumber = $Command.Extent.StartColumnNumber
							EndColumnNumber = $Command.Extent.EndColumnNumber
							StartOffset = $Command.Extent.StartOffset
							EndOffset = $Command.Extent.EndOffset

						}
					}
				}
			}
			CATCH
			{
				Write-Error -Message $($Error[0].Exception.Message)
			} 
		}
	} 
}
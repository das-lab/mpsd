function Expand-ScriptAlias
{

	[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
	PARAM (
		[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateScript({ Test-Path -Path $_ })]
		[Alias('FullName')]
		[System.String]$Path
	)
	PROCESS
	{
		FOREACH ($File in $Path)
		{
			Write-Verbose -Message '[PROCESS] $File'

			TRY
			{
				
				$ScriptContent = (Get-Content $File -Delimiter $([char]0))

				
				$AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
				ParseInput($ScriptContent, [ref]$null, [ref]$null)

				
				$Aliases = $AbstractSyntaxTree.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
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
				} | Sort-Object -Property EndOffset -Descending

				
				Foreach ($Alias in $Aliases)
				{
					
					if ($psCmdlet.ShouldProcess($file, "Expand Alias: $($Alias.alias) to $($Alias.definition) (startoffset: $($alias.StartOffset))"))
					{
						
						$ScriptContent = $ScriptContent.Remove($Alias.StartOffset, ($Alias.EndOffset - $Alias.StartOffset)).Insert($Alias.StartOffset, $Alias.Definition)
						
						Set-Content -Path $File -Value $ScriptContent -Confirm:$false
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
function Get-UserProfilePath
{
	
	[OutputType([string])]
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param (
		[Parameter(ParameterSetName = 'SID')]
		[string]$Sid,
		
		[Parameter(ParameterSetName = 'Username')]
		[string]$Username
	)
	
	process
	{
		try
		{
			if ($Sid)
			{
				$WhereBlock = { $_.PSChildName -eq $Sid }
			}
			elseif ($Username)
			{
				$WhereBlock = { $_.GetValue('ProfileImagePath').Split('\')[-1] -eq $Username }
			}
			else
			{
				$WhereBlock = { $null -ne $_.PSChildName }
			}
			Get-ChildItem 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' | Where-Object $WhereBlock | ForEach-Object { $_.GetValue('ProfileImagePath') }
		}
		catch
		{
			Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}
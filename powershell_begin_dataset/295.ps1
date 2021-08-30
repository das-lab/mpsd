function Test-PSFPowerShell
{

	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFPowerShell')]
	param (
		[Version]
		$PSMinVersion,
		
		[Version]
		$PSMaxVersion,
		
		[PSFramework.FlowControl.PSEdition]
		$Edition,
		
		[PSFramework.FlowControl.OperatingSystem]
		[Alias('OS')]
		$OperatingSystem,
		
		[switch]
		$Elevated
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug','start','param'
	}
	process
	{
		
		if ($PSMinVersion -and ($PSMinVersion -ge $PSVersionTable.PSVersion))
		{
			return $false
		}
		if ($PSMaxVersion -and ($PSMaxVersion -le $PSVersionTable.PSVersion))
		{
			return $false
		}
		
		
		
		if ($Edition -like "Desktop")
		{
			if ($PSVersionTable.PSEdition -eq "Core")
			{
				return $false
			}
		}
		if ($Edition -like "Core")
		{
			if ($PSVersionTable.PSEdition -ne "Core")
			{
				return $false
			}
		}
		
		
		
		if ($OperatingSystem)
		{
			switch ($OperatingSystem)
			{
				"MacOS"
				{
					if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
					if (-not $IsMacOS) { return $false }
				}
				"Linux"
				{
					if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
					if (-not $IsLinux) { return $false }
				}
				"Windows"
				{
					if (($PSVersionTable.PSVersion.Major -ge 6) -and (-not $IsWindows))
					{
						return $false
					}
				}
			}
		}
		
		
		
		if ($Elevated)
		{
			if (($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows))
			{
				$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
				$principal = New-Object Security.Principal.WindowsPrincipal $identity
				if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
				{
					return $false
				}
			}
		}
		
		
		return $true
	}
	end
	{
	
	}
}
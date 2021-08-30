function Set-PSFResultCache
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFResultCache')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[AllowEmptyCollection()]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('Value')]
		[Object]
		$InputObject,
		
		[boolean]
		$DisableCache = $false,
		
		[Switch]
		$PassThru,
		
		[string]
		$CommandName = (Get-PSCallStack)[0].Command
	)
	
	Begin
	{
		$IsPipeline = -not $PSBoundParameters.ContainsKey("InputObject")
		[PSFramework.ResultCache.ResultCache]::Function = $CommandName
		
		if ($IsPipeline -and (-not $DisableCache))
		{
			[PSFramework.ResultCache.ResultCache]::Result = @()
		}
	}
	Process
	{
		if ($IsPipeline)
		{
			if (-not $DisableCache) { [PSFramework.ResultCache.ResultCache]::Result += $PSItem }
			if ($PassThru) { $PSItem }
		}
		else
		{
			if (-not $DisableCache) { [PSFramework.ResultCache.ResultCache]::Result = $InputObject }
			if ($PassThru) { $InputObject }
		}
	}
	End
	{
		
	}
}
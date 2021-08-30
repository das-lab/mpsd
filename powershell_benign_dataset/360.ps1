function Get-PSFResultCache
{

	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFResultCache')]
	param (
		[ValidateSet('Value','All')]
		[string]
		$Type = 'Value'
	)
	
	switch ($Type)
	{
		'All'
		{
			New-Object PSObject -Property @{
				Result    = ([PSFramework.ResultCache.ResultCache]::Result)
				Function  = ([PSFramework.ResultCache.ResultCache]::Function)
				Timestamp = ([PSFramework.ResultCache.ResultCache]::Timestamp)
			}
		}
		'Value'
		{
			[PSFramework.ResultCache.ResultCache]::Result
		}
	}
}
if (-not (Test-Path "alias:Get-LastResult")) { New-Alias -Name Get-LastResult -Value Get-PSFResultCache -Description "A more intuitive name for users to call Get-PSFResultCache" }
if (-not (Test-Path "alias:glr")) { New-Alias -Name glr -Value Get-PSFResultCache -Description "A faster name for users to call Get-PSFResultCache" }
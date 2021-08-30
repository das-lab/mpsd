function Write-PSFMessageProxy
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Write-PSFMessageProxy')]
	param (
		[Parameter(Position = 0)]
		[Alias('Object', 'MessageData')]
		[string]
		$Message,
		
		[switch]
		$NoNewline,
		
		$Separator,
		
		[System.ConsoleColor]
		$ForegroundColor,
		
		[System.ConsoleColor]
		$BackgroundColor,
		
		[string[]]
		$Tags = 'proxied'
	)
	
	begin
	{
		$call = (Get-PSCallStack)[0].InvocationInfo
		$callStack = (Get-PSCallStack)[1]
		$FunctionName = $callStack.Command
		$ModuleName = $callstack.InvocationInfo.MyCommand.ModuleName
		if (-not $ModuleName) { $ModuleName = "<Unknown>" }
		$File = $callStack.Position.File
		$Line = $callStack.Position.StartLineNumber
		
		$splatParam = @{
			Tag		     = $Tags
			FunctionName = $FunctionName
			ModuleName   = $ModuleName
			File		 = $File
			Line		 = $Line
		}
		
		
		if (Test-PSFParameterBinding -ParameterName ForegroundColor)
		{
			$Message = "<c='$($ForegroundColor)'>{0}</c>" -f $Message
		}
	}
	process
	{
		switch ($call.InvocationName)
		{
			"Write-Host" { Write-PSFMessage -Level Important -Message $Message @splatParam }
			"Write-Verbose" { Write-PSFMessage -Level Verbose -Message $Message @splatParam }
			"Write-Warning" { Write-PSFMessage -Level Warning -Message $Message @splatParam }
			"Write-Debug" { Write-PSFMessage -Level System -Message $Message @splatParam }
			"Write-Information" { Write-PSFMessage -Level Important -Message $Message @splatParam }
			default { Write-PSFMessage -Level Verbose -Message $Message @splatParam }
		}
	}
}
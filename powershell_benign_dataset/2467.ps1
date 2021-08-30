function Start-Log
{
	
	[CmdletBinding()]
	param (
		[ValidateScript({ Split-Path $_ -Parent | Test-Path })]
		[string]$FilePath
	)
	
	try
	{
		if (!(Test-Path $FilePath))
		{
			
			New-Item $FilePath -Type File | Out-Null
		}
		
		
		
		$global:ScriptLogFilePath = $FilePath
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
}

function Write-Log
{
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Message,
		
		[Parameter()]
		[ValidateSet(1, 2, 3)]
		[int]$LogLevel = 1
	)
	
	try
	{
		$TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
		
		$Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
		$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
		$Line = $Line -f $LineFormat
		
		if (-not (Test-Path Variable:\ScriptLogFilePath))
		{
			Write-Verbose $Message
		}
		else
		{
			Add-Content -Value $Line -Path $ScriptLogFilePath
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
}










param([hashtable]$Theme)

Set-StrictMode -Version Latest




$Theme.HostBackgroundColor   = if ($Pscx:IsAdmin) { 'DarkRed' } else { 'Black' }
$Theme.HostForegroundColor   = if ($Pscx:IsAdmin) { 'White'   } else { 'Gray'  }
$Theme.PromptForegroundColor = if ($Pscx:IsAdmin) { 'Yellow'  } else { 'White' }
$Theme.PrivateData.ErrorForegroundColor = if ($Pscx:IsAdmin) { 'DarkCyan' }




$Theme.PromptScriptBlock = {
	param($Id) 
	
	if($NestedPromptLevel) 
	{
		new-object string ([char]0xB7), $NestedPromptLevel
	}
	
	"[$Id] $([char]0xBB)"	
}		




$Theme.UpdateWindowTitleScriptBlock = {
	(Get-Location)
	'-'
	'Windows PowerShell'

	if($Pscx:IsAdmin) 
	{ 
		'(Administrator)' 
	}
	
	if ($Pscx:IsWow64Process)
	{
		'(x86)'
	}
}

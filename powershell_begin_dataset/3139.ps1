$Title = "Continue"
$Info = "Would you like to continue?"
 
$Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
[int]$DefaultChoice = 0
$Opt =  $host.UI.PromptForChoice($Title , $Info, $Options, $DefaultChoice)

switch($Opt)
{
	0 { 
		Write-Verbose -Message "Yes"
	}
	
	1 { 
		Write-Verbose -Message "No" 
	}
}

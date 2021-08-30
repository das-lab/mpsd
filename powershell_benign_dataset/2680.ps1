

Param(
  [string]$SourceEnvironment,
  [string]$DestinationEnvironment
)

begin
{
	Clear-Host

	$path = Split-Path -parent $MyInvocation.MyCommand.Definition
    if ($env:PSModulePath -notlike "*$path\Modules\TriadModules\Modules*")
	{
	    "Adding ;$path\Modules\TriadModules\Modules to PSModulePath" | Write-Debug
		$env:PSModulePath += ";$path\Modules\TriadModules\Modules"
	}

	$config = [xml](Get-Content $path/config.xml -ErrorAction Stop)

    $defaultSourceEnvironment = "Dev" 
	$defaultDestinationEnvironment = "Uat" 


    if ($SourceEnvironment -eq $null)
    {
        $SourceEnvironment = $defaultSourceEnvironment
    } 

    if ($DestinationEnvironment -eq $null)
    {
        $DestinationEnvironment = $defaultDestinationEnvironment
    }

}

process
{		
	Get-TMPnPTemplatesForSiteCollection -Configuration $config.OuterXml -Environment $SourceEnvironment	
	Add-TMPnPTemplatesForSiteCollection -Configuration $config.OuterXml -SourceEnvironment $SourceEnvironment	-DestinationEnvironment $DestinationEnvironment	
}

end
{
    "Completed import!" | Write-Debug
}



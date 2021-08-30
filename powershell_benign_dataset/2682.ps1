

Param(
  [string]$Environment
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

    if ($Environment -eq $null -or $Environment -eq "")
    {
        $SourceEnvironment = $defaultSourceEnvironment
    } else
    {
        $SourceEnvironment = $Environment
    }

}

process
{
    Get-TMPnPTemplatesForSiteCollections -TemplatePath $path -Configuration $config.OuterXml -Environment $SourceEnvironment	
}

end
{
    "Completed export!" | Write-Debug
}
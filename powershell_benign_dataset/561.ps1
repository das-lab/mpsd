

function Connect-SPO
{
	[CmdletBinding()]
	param
	(
	    [Parameter(Mandatory=$true, Position=1)]
	    [string]$siteURL,
		
		[Parameter(Mandatory=$false, Position=2)]
		[bool]$online,

	    [Parameter(Mandatory=$false, Position=3)]
	    [string]$username,

	    [Parameter(Mandatory=$false, Position=4)]
	    [string]$password
	)
	Write-Host "Loading the CSOM library" -foregroundcolor black -backgroundcolor yellow
	[Reflection.Assembly]::LoadFrom((Get-ChildItem -Path $PSlib.Path -Filter "Microsoft.SharePoint.Client.dll" -Recurse).FullName)
	Write-Host "Succesfully loaded the CSOM library" -foregroundcolor black -backgroundcolor green

	Write-Host "Create client context for site $siteUrl" -foregroundcolor black -backgroundcolor yellow
	$SPOContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL)
	
	$SPOContext.RequestTimeOut = 1000 * 60 * 10;

	if ($online)
	{
		Write-Host "Setting SharePoint Online credentials" -foregroundcolor black -backgroundcolor yellow
		
		$SPOContext.AuthenticationMode = [Microsoft.SharePoint.Client.ClientAuthenticationMode]::Default
		$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

		$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
		$SPOContext.Credentials = $credentials
	}

	Write-Host "Check connection" -foregroundcolor black -backgroundcolor yellow
	$web = $SPOContext.Web
	$site = $SPOContext.Site
	$SPOContext.Load($web)
	$SPOContext.Load($site)
	$SPOContext.ExecuteQuery()
	
	Set-Variable -Name "clientContext" -Value $SPOContext -Scope Global
    Set-Variable -Name "rootSiteUrl" -Value $siteURL -Scope Global
	
	Write-Host "Succesfully connected" -foregroundcolor black -backgroundcolor green
}

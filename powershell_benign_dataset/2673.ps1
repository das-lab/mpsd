






[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false, HelpMessage="Optional administration credentials")]
    [PSCredential] $Credentials,
    [Parameter(Mandatory = $true, HelpMessage="Required Site Url")]
    [string] $Url,
    [Parameter(Mandatory = $false, HelpMessage="Optional Force switch")]
    [switch]$Force
)


if($Credentials -eq $null)
{
	$Credentials = Get-Credential -Message "Enter your credentials"
}


function GetWebs
{
    $separator = ","
    $sites = Get-SPOSite
	Get-SPOSubWebs -Web $sites.RootWeb -Recurse | foreach { $subIds += $_.ServerRelativeUrl + $separator }
	

	return $subIds.Split($separator)
}

try
{
    Connect-SPOnline $Url -Credentials $Credentials
	GetWebs | foreach {
		Write-Host "Really working hard in site $_" -ForegroundColor Yellow
        $cWeb = Get-SPOWeb -Identity $_
        if ($Force) {
            Disable-SPOFeature -Identity d95c97f3-e528-4da2-ae9f-32b3535fbb59 -Scope Web -Web $cWeb -Force
        }
        else {
            Disable-SPOFeature -Identity d95c97f3-e528-4da2-ae9f-32b3535fbb59 -Scope Web -Web $cWeb
        }

		Write-Host "Feature Deactivated." -ForegroundColor Green
	}
}
catch
{
    Write-Host -ForegroundColor Red "Exception occurred!"
    Write-Host -ForegroundColor Red "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host -ForegroundColor Red "Exception Message: $($_.Exception.Message)"
}


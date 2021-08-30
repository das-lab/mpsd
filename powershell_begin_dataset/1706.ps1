Function Test-ServiceNowURL {
    

    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param (
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

	begin {}
	process	{
        Write-Verbose "Testing url:  $Url"
		if ($Url -match '^\w+\..*\.\w+') {
            $true
        }
        else {
            Throw "The expected URL format is tenant.domain.com"
        }
    }
	end {}
}

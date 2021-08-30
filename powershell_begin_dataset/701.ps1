


function New-RsRestSession
{
    

    [cmdletbinding()]
    param
    (
        [string]
        $ReportPortalUri = ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportPortalUri),

        [ValidateSet("v1.0", "v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('Credentials')]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential)
    )

    if (($ReportPortalUri -eq $null) -or ($ReportPortalUri.Length -eq 0))
    {
        throw "Report Portal Uri must be specified!"
    }

    try
    {
        if ($ReportPortalUri -notlike '*/') 
        {
            $ReportPortalUri = $ReportPortalUri + '/'
        }
        $meUri = $ReportPortalUri + "api/$RestApiVersion/me"

        Write-Verbose "Making call to $meUri to create a session..."
        if ($Credential)
        {
            $result = Invoke-WebRequest -Uri $meUri -Credential $Credential -SessionVariable mySession -Verbose:$false -ErrorAction Stop
        }
        else
        {
            $result = Invoke-WebRequest -Uri $meUri -UseDefaultCredentials -SessionVariable mySession -Verbose:$false -ErrorAction Stop
        }

        if ($result.StatusCode -ne 200)
        {
            throw "Encountered non-success status code while contacting Report Portal. Status Code: $($result.StatusCode)"
        }
        else
        {
            
            
            try
            {
                $body = ConvertFrom-Json $result.Content
                if ($body -eq $null -or 
                    $body.Username -eq $null)
                {
                    throw "Invalid Report Portal Uri specified! Please make sure ReportPortalUri is the URL to the Report Portal!"
                }
            }
            catch
            {
                throw "Invalid Report Portal Uri specified! Please make sure ReportPortalUri is the URL to the Report Portal!"
            }
        }

        Write-Verbose "Reading XSRF Token cookie..."
        $xsrfToken = $mySession.Cookies.GetCookies($meUri)['XSRF-TOKEN'].Value
        if ($xsrfToken -eq $null)
        {
            Write-Warning "No XSRF Token detected! This might be due to XSRF token disabled."
        }
        else
        {
            Add-Type -AssemblyName 'System.Web' -ErrorAction Stop
            
            Write-Verbose "Decoding XSRF Token and setting it as a header of the session..."
            $mySession.Headers['X-XSRF-TOKEN'] = [System.Web.HttpUtility]::UrlDecode($xsrfToken)
        }

        
        
        $mySession.Headers['X-RSTOOLS-PORTALURI'] = $ReportPortalUri
        return $mySession
    }
    catch
    {
        throw (New-Object System.Exception("Failed to create a new session to $meUri : $($_.Exception.Message)", $_.Exception))
    }
}

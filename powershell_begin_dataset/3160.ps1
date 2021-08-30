

function Get-FederationEndpoint{

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
        HelpMessage="Domain name to get the ADFS endpoint for.")]
        [string]$domain,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Flag for authentication command output.")]
        [switch]$cmd
    )

    
    $email = "test@"+$domain

    
    $url = "https://login.microsoftonline.com/common/userrealm/?user="+$email+"&api-version=2.1&checkForMicrosoftAccount=true";

    
    $EmailTestResults = new-object system.data.datatable
    $EmailTestResults.columns.add("Domain") | Out-Null
    $EmailTestResults.columns.add("InternalDomain") | Out-Null
    $EmailTestResults.columns.add("Type") | Out-Null
    $EmailTestResults.columns.add("BrandName") | Out-Null
    $EmailTestResults.columns.add("SSOEndpoints") | Out-Null
    $EmailTestResults.columns.add("AuthURL") | Out-Null
   
    try{
            
            $JSON = Invoke-RestMethod -Uri $url
        }
    catch{
            Write-Host "`nThe Request out to Microsoft failed."
        }

        
        $NameSpaceType = $JSON[0].NameSpaceType

        if ($NameSpaceType -eq "Managed"){
            
            
            $EmailTestResults.Rows.Add($JSON[0].DomainName, "NA", "Managed", $JSON[0].FederationBrandName, "NA", "NA") | Out-Null

            if ($cmd){

                
                Write-Host "`nDomain is managed by Microsoft, try guessing creds this way:`n`n`t`$msolcred = get-credential`n`tconnect-msolservice -credential `$msolcred"
                
                if (Get-Module -Name MsOnline){}
                else{Write-Host "`n`t*Requires AzureAD PowerShell module to be installed and loaded - https://msdn.microsoft.com/en-us/library/jj151815.aspx"}
            }
        }
        ElseIf ($NameSpaceType -eq "Federated"){

            
            $username = $email.Split("@")[0]
            $domain = $JSON[0].DomainName
            $ADFSBaseUri = [string]$JSON[0].AuthURL.Split("/")[0]+"//"+[string]$JSON[0].AuthURL.Split("/")[2]+"/"
            $AppliesTo = $ADFSBaseUri+"adfs/services/trust/13/usernamemixed"

            try {
                
                $domainRequest = Invoke-WebRequest -Uri $JSON[0].AuthURL
                $domainRequest.RawContent -match "userNameValue = '(.*?)\\\\' \+ userName\." | Out-Null
                $realDomain = $Matches[1]
                }
            catch{$realDomain = "NA"}

            $SSOSitesURL = $ADFSBaseUri+"adfs/ls/idpinitiatedsignon.aspx?"

            try {
                
                $SSORequest = Invoke-WebRequest -Uri $SSOSitesURL
                $endpoints = @()
                foreach ($element in $SSORequest.AllElements) {if ($element.tagName -match "OPTION"){$endpoints += $element.outerText}}
                if ($endpoints.Length -eq 0){$endpoints = "NA"}
                }
            catch{$endpoints = "NA"}
            
            
            $EmailTestResults.Rows.Add($JSON[0].DomainName, $realDomain, "Federated", $JSON[0].FederationBrandName, $endpoints -join ', ', $JSON[0].AuthURL) | Out-Null


            if ($cmd){

                
                Write-Host "`nMake sure you use the correct Username and Domain parameters when you try to authenticate!`n`nAuthentication Command:`nInvoke-ADFSSecurityTokenRequest -ClientCredentialType UserName -ADFSBaseUri"$ADFSBaseUri" -AppliesTo "$AppliesTo" -UserName '"$username"' -Password 'Winter2016' -Domain '"$domain"' -OutputType Token -SAMLVersion 2 -IgnoreCertificateErrors"
                
                try {Get-Command -Name Invoke-ADFSSecurityTokenRequest -ErrorAction Stop}
                catch{Write-Host `n`n'*Requires the command imported from here - https://gallery.technet.microsoft.com/scriptcenter/Invoke-ADFSSecurityTokenReq-09e9c90c'}
            }
        }
        Else{
            
            
            $EmailTestResults.Rows.Add("NA", "NA", "NA", "NA", "NA", "NA") | Out-Null
        }

    Return $EmailTestResults
}



[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the internal FQDN of the Primary ADFS server that will be used as context for configuration.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$Computer,

    [parameter(Mandatory=$true, HelpMessage="Specify the top-level verified domain for your Azure Active Directory tenant that will be converted to federated authentication.")]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName,

    [parameter(Mandatory=$false, HelpMessage="Use this switch if you need support for multiple top-level domains.")]
    [ValidateNotNullOrEmpty()]
    [switch]$SupportMultipleDomain
)
Begin {
    
    try {
        Import-Module -Name MsOnline -ErrorAction Stop -Verbose:$false
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to load the Azure Active Directory PowerShell module" ; break
    }
}
Process {
    
    $Credentials = Get-Credential -Message "Enter the username and password for a Global Admin account:" -Verbose:$false

    
    if ($Credentials -ne $null) {
        
        try {
            Write-Verbose -Message "Attempting to connect to Microsoft Online Services"
            Connect-MsolService -Credential $Credentials -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to connect to Microsoft Online Services, error message was: $($_.Exception.Message)" ; break
        }

        
        try {
            Write-Verbose -Message "Setting on-premise Active Directory Federation Services computer context"
            if ($PSCmdlet.ShouldProcess($Computer, "Set context")) {
                Set-MsolADFSContext -Computer $Computer -ErrorAction Stop -Verbose:$false
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An issue occured while configuring ADFS computer context, error message was: $($_.Exception.Message)" ; break
        }

        
        try {
            Write-Verbose -Message "Retrieving domain name from Microsoft Online Services"
            $MsolDomain = Get-MsolDomain -DomainName $DomainName -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "An issue occured while retrieving domain from Microsoft Online Services, error message was: $($_.Exception.Message)" ; break
        }

        
        if ($MsolDomain.Status -like "Verified") {
            if ($MsolDomain.Authentication -like "Managed") {
                try {
                    
                    $MsolFederatedDomainArgs = @{
                        DomainName = $DomainName
                        ErrorAction = "Stop"
                        Verbose = $false
                    }

                    
                    if ($PSBoundParameters.ContainsKey("SupportMultipleDomain")) {
                        $MsolFederatedDomainArgs.Add("SupportMultipleDomain", $true)
                    }

                    
                    Write-Verbose -Message "Converting domain name '$($MsolDomain.Name)' to federated authentication"
                    if ($PSCmdlet.ShouldProcess($DomainName, "Convert")) {
                        Convert-MsolDomainToFederated @MsolFederatedDomainArgs
                    }
                }
                catch [System.Exception] {
                    Write-Warning -Message "An issue occured while converting domain name to federated authentication, error message was: $($_.Exception.Message)"
                }

                
                if ($PSBoundParameters.ContainsKey("ShowFederationProperties")) {
                    Get-MsolFederationProperty –DomainName $DomainName -Verbose:$false
                }
            }
            else {
                Write-Warning -Message "An issue occured while validating the domain name authentication configuration. Domain name '$($MsolDomain.Name)' is not currently set for Managed authentication" ; break
            }
        }
        else {
            Write-Warning -Message "An issue occured while validating if domain name has been verified. Domain name '$($MsolDomain.Name)' is not currently verified, please complete the verification process before you continue converting the domain name" ; break
        }
    }
    else {
        Write-Warning -Message "Unable construct credentials object, error message was: $($_.Exception.Message)" ; break
    }
}
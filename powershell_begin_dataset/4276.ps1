function Get-LAPSPasswords
{
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Credentials to use when connecting to a Domain Controller.")]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Domain controller for Domain and Site that you want to query against.")]
        [string]$DomainController,

        [Parameter(Mandatory=$false,
        HelpMessage="Maximum number of Objects to pull from AD, limit is 1,000.")]
        [int]$Limit = 1000,

        [Parameter(Mandatory=$false,
        HelpMessage="scope of a search as either a base, one-level, or subtree search, default is subtree.")]
        [ValidateSet("Subtree","OneLevel","Base")]
        [string]$SearchScope = "Subtree",

        [Parameter(Mandatory=$false,
        HelpMessage="Distinguished Name Path to limit search to.")]

        [string]$SearchDN
    )
    Begin
    {
        if ($DomainController -and $Credential.GetNetworkCredential().Password)
        {
            $objDomain = New-Object System.DirectoryServices.DirectoryEntry "LDAP://$($DomainController)", $Credential.UserName,$Credential.GetNetworkCredential().Password
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher $objDomain
        }
        else
        {
            $objDomain = [ADSI]""  
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher $objDomain
        }
    }

    Process
    {
        
        Write-Verbose "[*] Grabbing computer accounts from Active Directory..."

        
        $TableAdsComputers = New-Object System.Data.DataTable 
        $TableAdsComputers.Columns.Add('Hostname') | Out-Null
        $TableAdsComputers.Columns.Add('Stored') | Out-Null
        $TableAdsComputers.Columns.Add('Readable') | Out-Null
        $TableAdsComputers.Columns.Add('Password') | Out-Null
        $TableAdsComputers.Columns.Add('Expiration') | Out-Null

        
        
        
        $CompFilter = "(&(objectCategory=Computer))"
        $ObjSearcher.PageSize = $Limit
        $ObjSearcher.Filter = $CompFilter
        $ObjSearcher.SearchScope = "Subtree"

        if ($SearchDN)
        {
            $objSearcher.SearchDN = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($SearchDN)")
        }

        $ObjSearcher.FindAll() | ForEach-Object {

            
            $CurrentHost = $($_.properties['dnshostname'])
            $CurrentUac = $($_.properties['useraccountcontrol'])
			$CurrentPassword = $($_.properties['ms-MCS-AdmPwd'])
            if ($_.properties['ms-MCS-AdmPwdExpirationTime'] -ge 0){$CurrentExpiration = $([datetime]::FromFileTime([convert]::ToInt64($_.properties['ms-MCS-AdmPwdExpirationTime'],10)))}
            else{$CurrentExpiration = "NA"}
                        
            $PasswordAvailable = 0
            $PasswordStored = 1

            
            
            
            $CurrentUacBin = [convert]::ToString($CurrentUac,2)

            
            $DisableOffset = $CurrentUacBin.Length - 2
            $CurrentDisabled = $CurrentUacBin.Substring($DisableOffset,1)

            
            if ($CurrentExpiration -eq "NA"){$PasswordStored = 0}


            if ($CurrentPassword.length -ge 1){$PasswordAvailable = 1}


            
            if ($CurrentDisabled  -eq 0){
                
                $TableAdsComputers.Rows.Add($CurrentHost,$PasswordStored,$PasswordAvailable,$CurrentPassword, $CurrentExpiration) | Out-Null
            }

            
            $TableAdsComputers | Sort-Object {$_.Hostname} -Descending
         }
    }
    End
    {
    }
}
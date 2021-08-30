function Get-ADSITokenGroup
{
    
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Alias('UserName', 'Identity')]
        [String]$SamAccountName,

        [Alias('RunAs')]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Alias('DomainDN', 'Domain')]
        [String]$DomainDistinguishedName = $(([adsisearcher]"").Searchroot.path),

        [Alias('ResultLimit', 'Limit')]
        [int]$SizeLimit = '100'
    )
    BEGIN
    {
        $GroupList = ""
    }
    PROCESS
    {
        TRY
        {
            
            $Search = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction 'Stop'
            $Search.SizeLimit = $SizeLimit
            $Search.SearchRoot = $DomainDN
            
            $Search.Filter = "(&((objectclass=user)(samaccountname=$SamAccountName)))"

            
            IF ($PSBoundParameters['Credential'])
            {
                $Cred = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDistinguishedName, $($Credential.UserName), $($Credential.GetNetworkCredential().password)
                $Search.SearchRoot = $Cred
            }

            
            IF ($DomainDistinguishedName)
            {
                IF ($DomainDistinguishedName -notlike "LDAP://*") { $DomainDistinguishedName = "LDAP://$DomainDistinguishedName" }
                Write-Verbose -Message "[PROCESS] Different Domain specified: $DomainDistinguishedName"
                $Search.SearchRoot = $DomainDistinguishedName
            }

            $Search.FindAll() | ForEach-Object -Process {
                $Account = $_
                $AccountGetDirectory = $Account.GetDirectoryEntry();

                
                $AccountGetDirectory.GetInfoEx(@("tokenGroups"), 0)


                $($AccountGetDirectory.Get("tokenGroups")) |
                ForEach-Object -Process {
                    
                    $Principal = New-Object System.Security.Principal.SecurityIdentifier($_, 0)

                    
                    $Properties = @{
                        SamAccountName = $Account.properties.samaccountname -as [string]
                        GroupName = $principal.Translate([System.Security.Principal.NTAccount])
                    }

                    
                    New-Object -TypeName PSObject -Property $Properties
                }
            } | Group-Object -Property groupname |
            ForEach-Object {
                New-Object -TypeName PSObject -Property @{
                    SamAccountName = $_.group.samaccountname | Select-Object -Unique
                    GroupName = $_.Name
                    Count = $_.Count
                }
            }
        }
        CATCH
        {
            Write-Warning -Message "[PROCESS] Something wrong happened!"
            Write-Warning -Message $error[0].Exception.Message
        }
    }
    END { Write-Verbose -Message "[END] Function Get-ADSITokenGroup End." }
}
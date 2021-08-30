$UserSam = "TestAccount"

$Search = New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction 'Stop'
$Search.Filter = "(&((objectclass=user)(samaccountname=$UserSam)))"
$Search.FindAll() | ForEach-Object -Process {
                $Account = $_
                $AccountGetDirectory = $Account.GetDirectoryEntry();

                
                $AccountGetDirectory.GetInfoEx(@("tokenGroups"), 0)


                $($AccountGetDirectory.Get("tokenGroups"))|
                ForEach-Object -Process {
                        
                        $Principal = New-Object System.Security.Principal.SecurityIdentifier($_, 0)
                        $domainName = [adsi]"LDAP://$($Principal.AccountDomainSid)"

                        
                        
                        $Properties = @{
                            SamAccountName = $Account.properties.samaccountname -as [string]
                            GroupName = $principal.Translate([System.Security.Principal.NTAccount])
                        }
                        
                        New-Object -TypeName PSObject -Property $Properties
                    }
}
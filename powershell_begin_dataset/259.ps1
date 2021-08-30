function Get-ADSiteAndSubnet {

    [CmdletBinding()]
    PARAM()
    BEGIN {Write-Verbose -Message "[BEGIN] Starting Script..."}
    PROCESS
    {
        TRY{
            
            $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $SiteInfo = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites

            
            $ForestType = [System.DirectoryServices.ActiveDirectory.DirectoryContexttype]"forest"
            $ForestContext = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList $ForestType,$Forest

            
            $Configuration = ([ADSI]"LDAP://RootDSE").configurationNamingContext

            
            $SubnetsContainer = [ADSI]"LDAP://CN=Subnets,CN=Sites,$Configuration"
            $SubnetsContainerchildren = $SubnetsContainer.Children

            FOREACH ($item in $SiteInfo){

                Write-Verbose -Message "[PROCESS] SITE: $($item.name)"

                $output = @{
                    Name = $item.name
                }
                    FOREACH ($i in $item.Subnets.name){
                        Write-verbose -message "[PROCESS] SUBNET: $i"
                        $output.Subnet = $i
                        $SubnetAdditionalInfo = $SubnetsContainerchildren.Where({$_.name -match $i})

                        Write-verbose -message "[PROCESS] SUBNET: $i - DESCRIPTION: $($SubnetAdditionalInfo.Description)"
                        $output.Description = $($SubnetAdditionalInfo.Description)

                        Write-verbose -message "[PROCESS] OUTPUT INFO"

                        New-Object -TypeName PSObject -Property $output
                    }
            }
        }
        CATCH
        {
            Write-Warning -Message "[PROCESS] Something Wrong Happened"
            Write-Warning -Message $Error[0]
        }
    }
    END
    {
        Write-Verbose -Message "[END] Script Completed!"
    }
}
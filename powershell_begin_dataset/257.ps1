function Get-ADSiteInventory {

    [CmdletBinding()]
    PARAM()
    PROCESS
    {
        TRY{
            
            $ScriptName = (Get-Variable -name MyInvocation -Scope 0 -ValueOnly).Mycommand

            
            Write-Verbose -message "[$ScriptName][PROCESS] Retrieve current Forest"
            $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            Write-Verbose -message "[$ScriptName][PROCESS] Retrieve current Forest sites"
            $SiteInfo = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites

            
            Write-Verbose -message "[$ScriptName][PROCESS] Create forest context"
            $ForestType = [System.DirectoryServices.ActiveDirectory.DirectoryContexttype]"forest"
            $ForestContext = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList $ForestType,$Forest

            
            Write-Verbose -message "[$ScriptName][PROCESS] Retrieve RootDSE Configuration Naming Context"
            $Configuration = ([ADSI]"LDAP://RootDSE").configurationNamingContext

            
            Write-Verbose -message "[$ScriptName][PROCESS] Get the Subnet Container"
            $SubnetsContainer = [ADSI]"LDAP://CN=Subnets,CN=Sites,$Configuration"

            FOREACH ($item in $SiteInfo){

                Write-Verbose -Message "[$ScriptName][PROCESS] SITE: $($item.name)"

                
                Write-Verbose -Message "[$ScriptName][PROCESS] SITE: $($item.name) - Getting Site Links"
                $LinksInfo = ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::FindByName($ForestContext,$($item.name))).SiteLinks

                
                Write-Verbose -Message "[$ScriptName][PROCESS] SITE: $($item.name) - Preparing Output"

                New-Object -TypeName PSObject -Property @{
                    Name= $item.Name
                    SiteLinks = $item.SiteLinks -join ","
                    Servers = $item.Servers -join ","
                    Domains = $item.Domains -join ","
                    Options = $item.options
                    AdjacentSites = $item.AdjacentSites -join ','
                    InterSiteTopologyGenerator = $item.InterSiteTopologyGenerator
                    Location = $item.location
                    Subnets = ( $info = Foreach ($i in $item.Subnets.name){
                        $SubnetAdditionalInfo = $SubnetsContainer.Children | Where-Object {$_.name -like "*$i*"}
                        "$i -- $($SubnetAdditionalInfo.Description)" }) -join ","
                    

                    
                        SiteLinksCost = $LinksInfo.Cost -join ","
                        ReplicationInterval = $LinksInfo.ReplicationInterval -join ','
                        ReciprocalReplicationEnabled = $LinksInfo.ReciprocalReplicationEnabled -join ','
                        NotificationEnabled = $LinksInfo.NotificationEnabled -join ','
                        TransportType = $LinksInfo.TransportType -join ','
                        InterSiteReplicationSchedule = $LinksInfo.InterSiteReplicationSchedule -join ','
                        DataCompressionEnabled = $LinksInfo.DataCompressionEnabled -join ','
                    
                    
                }
            }
        }
        CATCH
        {
            
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    END
    {
        Write-Verbose -Message "[$ScriptName][END] Script Completed!"
    }
}




Function Add-ADSubnet{

    [CmdletBinding()]
    PARAM(
        [Parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Subnet name to create")]
        [Alias("Name")]
        [String]$Subnet,
        [Parameter(
            Mandatory=$true,
            Position=2,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Site to which the subnet will be applied")]
        [Alias("Site")]
        [String]$SiteName,
        [Parameter(
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Description of the Subnet")]
        [String]$Description,
        [Parameter(
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Location of the Subnet")]
        [String]$location
    )
    PROCESS{
            TRY{
                $ErrorActionPreference = 'Stop'

                
                $Configuration = ([ADSI]"LDAP://RootDSE").configurationNamingContext

                
                $SubnetsContainer = [ADSI]"LDAP://CN=Subnets,CN=Sites,$Configuration"

                
                Write-Verbose -Message "$subnet - Creating the subnet object..."
                $SubnetObject = $SubnetsContainer.Create('subnet', "cn=$Subnet")

                
                $SubnetObject.put("siteObject","cn=$SiteName,CN=Sites,$Configuration")

                
                IF ($PSBoundParameters['Description']){
                    $SubnetObject.Put("description",$Description)
                }

                
                IF ($PSBoundParameters['Location']){
                    $SubnetObject.Put("location",$Location)
                }
                $SubnetObject.setinfo()
                Write-Verbose -Message "$subnet - Subnet added."
            }
            CATCH{
                Write-Warning -Message "An error happened while creating the subnet: $subnet"
                $error[0].Exception
            }
    }
    END{
        Write-Verbose -Message "Script Completed"
    }
}
function Get-ADFSMORole
{

    [CmdletBinding()]
    PARAM (
        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        [pscredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    TRY
    {
        
        IF (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction 'Stop' -Verbose:$false }

        IF ($PSBoundParameters['Credential'])
        {
            
            $ForestRoles = Get-ADForest -Credential $Credential -ErrorAction 'Stop' -ErrorVariable ErrorGetADForest
            $DomainRoles = Get-ADDomain -Credential $Credential -ErrorAction 'Stop' -ErrorVariable ErrorGetADDomain
        }
        ELSE
        {
            
            $ForestRoles = Get-ADForest
            $DomainRoles = Get-ADDomain
        }

        
        $Properties = @{
            SchemaMaster = $ForestRoles.SchemaMaster
            DomainNamingMaster = $ForestRoles.DomainNamingMaster
            InfraStructureMaster = $DomainRoles.InfraStructureMaster
            RIDMaster = $DomainRoles.RIDMaster
            PDCEmulator = $DomainRoles.PDCEmulator
        }

        New-Object -TypeName PSObject -Property $Properties
    }
    CATCH
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
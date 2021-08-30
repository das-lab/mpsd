function Get-ADGPOReplication
{
    
    
    [CmdletBinding()]
    PARAM (
        [parameter(Mandatory = $True, ParameterSetName = "One")]
        [String[]]$GPOName,
        [parameter(Mandatory = $True, ParameterSetName = "All")]
        [Switch]$All
    )
    BEGIN
    {
        TRY
        {
            if (-not (Get-Module -Name ActiveDirectory)) { Import-Module -Name ActiveDirectory -ErrorAction Stop -ErrorVariable ErrorBeginIpmoAD }
            if (-not (Get-Module -Name GroupPolicy)) { Import-Module -Name GroupPolicy -ErrorAction Stop -ErrorVariable ErrorBeginIpmoGP }
        }
        CATCH
        {
            Write-Warning -Message "[BEGIN] Something wrong happened"
            IF ($ErrorBeginIpmoAD) { Write-Warning -Message "[BEGIN] Error while Importing the module Active Directory" }
            IF ($ErrorBeginIpmoGP) { Write-Warning -Message "[BEGIN] Error while Importing the module Group Policy" }
            Write-Warning -Message "[BEGIN] $($Error[0].exception.message)"
        }
    }
    PROCESS
    {
        FOREACH ($DomainController in ((Get-ADDomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetDC -filter *).hostname))
        {
            TRY
            {
                IF ($psBoundParameters['GPOName'])
                {
                    Foreach ($GPOItem in $GPOName)
                    {
                        $GPO = Get-GPO -Name $GPOItem -Server $DomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetGPO

                        [pscustomobject][ordered] @{
                            GroupPolicyName = $GPOItem
                            DomainController = $DomainController
                            UserVersion = $GPO.User.DSVersion
                            UserSysVolVersion = $GPO.User.SysvolVersion
                            ComputerVersion = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                    }
                }
                IF ($psBoundParameters['All'])
                {
                    $GPOList = Get-GPO -All -Server $DomainController -ErrorAction Stop -ErrorVariable ErrorProcessGetGPOAll

                    foreach ($GPO in $GPOList)
                    {
                        [pscustomobject][ordered] @{
                            GroupPolicyName = $GPO.DisplayName
                            DomainController = $DomainController
                            UserVersion = $GPO.User.DSVersion
                            UserSysVolVersion = $GPO.User.SysvolVersion
                            ComputerVersion = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                    }
                }
            }
            CATCH
            {
                Write-Warning -Message "[PROCESS] Something wrong happened"
                IF ($ErrorProcessGetDC) { Write-Warning -Message "[PROCESS] Error while running retrieving Domain Controllers with Get-ADDomainController" }
                IF ($ErrorProcessGetGPO) { Write-Warning -Message "[PROCESS] Error while running Get-GPO" }
                IF ($ErrorProcessGetGPOAll) { Write-Warning -Message "[PROCESS] Error while running Get-GPO -All" }
                Write-Warning -Message "[PROCESS] $($Error[0].exception.message)"
            }
        }
    }
}

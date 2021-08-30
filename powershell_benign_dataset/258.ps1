Function Get-AccountLockedOut
{



    
    [CmdletBinding()]
    param (
        [string]$DomainName = $env:USERDOMAIN,
        [Parameter()]
        [ValidateNotNullorEmpty()]
        [string]$UserName = '*',
        [datetime]$StartTime = (Get-Date).AddDays(-1),
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    BEGIN
    {
        TRY
        {
            
            $TimeDifference = (Get-Date) - $StartTime

            Write-Verbose -Message "[BEGIN] Looking for PDC..."

            function Get-PDCServer
            {
    
                PARAM (
                    $Domain = $env:USERDOMAIN,
                    $Credential = [System.Management.Automation.PSCredential]::Empty
                )

                IF ($PSBoundParameters['Credential'])
                {

                    [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
                    (New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList 'Domain', $Domain, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                    ).PdcRoleOwner.name
                }
                ELSE
                {
                    [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
                    (New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain))
                    ).PdcRoleOwner.name
                }
            }

            Write-Verbose -Message "[BEGIN] PDC is $(Get-PDCServer)"
        }
        CATCH
        {
            Write-Warning -Message "[BEGIN] Something wrong happened"
            Write-Warning -Message $Error[0]
        }

    }
    PROCESS
    {
        TRY
        {
            
            $Splatting = @{ }

            
            IF ($PSBoundParameters['Credential'])
            {
                Write-Verbose -Message "[PROCESS] Credential Specified"
                $Splatting.Credential = $Credential
                $Splatting.ComputerName = $(Get-PDCServer -Domain $DomainName -Credential $Credential)
            }
            ELSE
            {
                $Splatting.ComputerName =$(Get-PDCServer -Domain $DomainName)
            }

            
            Write-Verbose -Message "[PROCESS] Querying PDC for LockedOut Account in the last Days:$($TimeDifference.days) Hours: $($TimeDifference.Hours) Minutes: $($TimeDifference.Minutes) Seconds: $($TimeDifference.seconds)"
            Invoke-Command @Splatting -ScriptBlock {

                
                Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4740; StartTime = $Using:StartTime } |
                Where-Object { $_.Properties[0].Value -like "$Using:UserName" } |
                Select-Object -Property TimeCreated,
                              @{ Label = 'UserName'; Expression = { $_.Properties[0].Value } },
                              @{ Label = 'ClientName'; Expression = { $_.Properties[1].Value } }
            } | Select-Object -Property TimeCreated, UserName, ClientName
        }
        CATCH
        {

        }
    }
}

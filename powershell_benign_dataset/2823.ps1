Function ConvertTo-GraphiteMetric
{

    param
    (
        [CmdletBinding()]
        [parameter(Mandatory = $true)]
        [string]$MetricToClean,

        [parameter(Mandatory = $false)]
        [switch]$RemoveUnderscores,

        [parameter(Mandatory = $false)]
        [switch]$NicePhysicalDisks,

        [parameter(Mandatory = $false)]
        [string]$HostName=$env:COMPUTERNAME,

        
        [parameter(Mandatory = $false)]
        [System.Collections.Specialized.OrderedDictionary]$MetricReplacementHash
    )

    
    $renameHost = $false

    
    if ($HostName -ne $env:COMPUTERNAME)
    {
        
        $hostGuid = ([guid]::NewGuid()).ToString().Replace('-','')

        
        $MetricToClean = $MetricToClean -replace "\\\\$($env:COMPUTERNAME)\\","\\$($hostGuid)\"

        $renameHost = $true
        
    }

    if ($MetricReplacementHash -ne $null)
    {
        $cleanNameOfSample = $MetricToClean
        
        ForEach ($m in $MetricReplacementHash.GetEnumerator())
        {
            If ($m.Value -cmatch '
            {
                
                $cleanNameOfSample -match $m.Name | Out-Null

                
                $replacementString = $m.Value -replace '

                $cleanNameOfSample = $cleanNameOfSample -replace $m.Name, $replacementString
            }
            else
            {
                Write-Verbose "Replacing: $($m.Name) With : $($m.Value)"
                $cleanNameOfSample = $cleanNameOfSample -replace $m.Name, $m.Value
            }
        }
    }
    else
    {
        
        $cleanNameOfSample = $MetricToClean -replace '^\\\\', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\\\\', '.'

        
        $cleanNameOfSample = $cleanNameOfSample -replace ':', '.'

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\/', '-'

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\\', '.'

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\(', '.'

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\)', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\]', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\[', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\%', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\s+', ''

        
        $cleanNameOfSample = $cleanNameOfSample -replace '\.\.', '.'
    }

    if ($RemoveUnderscores)
    {
        Write-Verbose "Removing Underscores as the switch is enabled"
        $cleanNameOfSample = $cleanNameOfSample -replace '_', ''
    }

    if ($NicePhysicalDisks)
    {
        Write-Verbose "NicePhyiscalDisks switch is enabled"

        
        $driveLetter = ([regex]'physicaldisk\.\d([a-zA-Z])').match($cleanNameOfSample).groups[1].value

        
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.\d([a-zA-Z])', ('physicaldisk.' + $driveLetter + '-drive')

        
        $niceDriveLetter = ([regex]'physicaldisk\.(.*)\.avg\.').match($cleanNameOfSample).groups[1].value

        
        $cleanNameOfSample = $cleanNameOfSample -replace 'physicaldisk\.(.*)\.avg\.', ('physicaldisk.' + $niceDriveLetter + '.')
    }

    
    if ($renameHost)
    {
        Write-Verbose "Replacing hostGuid '$($hostGuid)' with requested Hostname '$($HostName)'"
        $cleanNameOfSample = $cleanNameOfSample -replace $hostGuid,$HostName
    }


    Write-Output $cleanNameOfSample
}
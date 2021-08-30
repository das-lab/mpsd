

[CmdletBinding()]
param ()

begin {
	Set-StrictMode -Version Latest
	$ErrorActionPreference = 'Stop'
}

process {
	try {
        
        
        
        
	    $Netstat = (netstat -anb | where {$_ -and ($_ -ne 'Active Connections')}).Trim() | Select-Object -Skip 1 | foreach {$_ -replace '\s{2,}','|'}

        $i = 0
        foreach ($Line in $Netstat) { 
            
            $Out = @{
                'Protocol' = ''
                'State' = ''
                'IPVersion' = ''
                'LocalAddress' = ''
                'LocalPort' = ''
                'RemoteAddress' = ''
                'RemotePort' = ''
                'ProcessOwner' = ''
                'Service' = ''
            }
            
            if ($Line -cmatch '^[A-Z]{3}\|') {
                $Cols = $Line.Split('|')
                $Out.Protocol = $Cols[0]
                
                if ($Cols.Count -eq 4) {
                    $Out.State = $Cols[3]
                }
                
                if ($Cols[1].StartsWith('[')) {
                    $Out.IPVersion = 'IPv6'
                    $Out.LocalAddress = $Cols[1].Split(']')[0].TrimStart('[')
                    $Out.LocalPort = $Cols[1].Split(']')[1].TrimStart(':')
                    if ($Cols[2] -eq '*:*') {
                       $Out.RemoteAddress = '*'
                       $Out.RemotePort = '*'
                    } else {
                       $Out.RemoteAddress = $Cols[2].Split(']')[0].TrimStart('[')
                       $Out.RemotePort = $Cols[2].Split(']')[1].TrimStart(':')
                    }
                } else {
                    $Out.IPVersion = 'IPv4'
                    $Out.LocalAddress = $Cols[1].Split(':')[0]
                    $Out.LocalPort = $Cols[1].Split(':')[1]
                    $Out.RemoteAddress = $Cols[2].Split(':')[0]
                    $Out.RemotePort = $Cols[2].Split(':')[1]
                }
                
                
                
                
                $LinesUntilNextPortNum = ($Netstat | Select-Object -Skip $i | Select-String -Pattern '^[A-Z]{3}\|' -NotMatch | Select-Object -First 1).LineNumber
                
                $NextPortLineNum = $i + $LinesUntilNextPortNum
                
                $PortAttribs = $Netstat[($i+1)..$NextPortLineNum]
                
                $Out.ProcessOwner = $PortAttribs -match '^\[.*\.exe\]|Can'
                if ($Out.ProcessOwner) {
                    
                    $Out.ProcessOwner = ($Out.ProcessOwner -replace '\[|\]','')[0]
                }
                
                if ($PortAttribs -match '^\w+$') {
                    $Out.Service = ($PortAttribs -match '^\w+$')[0]
                }
                [pscustomobject]$Out
            }
            
            $i++
        }    	
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}
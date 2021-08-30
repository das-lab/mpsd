
function Set-CHostsEntry
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        
        $IPAddress,

        [Parameter(Mandatory=$true)]
        [string]
        
        $HostName,

        [string]
        
        $Description,

        [string]
        
        $Path = (Get-CPathToHostsFile)
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
 
    $matchPattern = '^(?<IP>[0-9a-f.:]+)\s+(?<HostName>[^\s
    $lineFormat = "{0,-45}  {1}{2}"
    
    if(-not (Test-Path $Path))
    {
        Write-Warning "Creating hosts file at: $Path"
        New-Item $Path -ItemType File
    }
    
    [string[]]$lines = Read-CFile -Path $Path -ErrorVariable 'cmdErrors'
    if( $cmdErrors )
    {
        return
    }    
    
    $outLines = New-Object 'Collections.ArrayList'
    $found = $false
    $lineNum = 0
    $updateHostsFile = $false
     
    foreach($line in $lines)
    {
        $lineNum += 1
        
        if($line.Trim().StartsWith("
        {
            [void] $outlines.Add($line)
        }
        elseif($line -match $matchPattern)
        {
            $ip = $matches["IP"]
            $hn = $matches["HostName"]
            $tail = $matches["Tail"].Trim()
            if( $HostName -eq $hn )
            {
                if($found)
                {
                    
                    [void] $outlines.Add("
                    $updateHostsFile = $true
                    continue
                }
                $ip = $IPAddress
                $tail = if( $Description ) { "`t
                $found = $true   
            }
            else
            {
                $tail = "`t{0}" -f $tail
            }
           
            if( $tail.Trim() -eq "
            {
                $tail = ""
            }

            $outline = $lineformat -f $ip, $hn, $tail
            $outline = $outline.Trim()
            if( $outline -ne $line )
            {
                $updateHostsFile = $true
            }

            [void] $outlines.Add($outline)
                
        }
        else
        {
            Write-Warning ("Hosts file {0}: line {1}: invalid entry: {2}" -f $Path,$lineNum,$line)
            $outlines.Add( ('
        }

    }
     
    if(-not $found)
    {
       
       $tail = "`t
       if($tail.Trim() -eq "
       {
           $tail = ""
       }
           
       $outline = $lineformat -f $IPAddress, $HostName, $tail
       $outline = $outline.Trim()
       [void] $outlines.Add($outline)
       $updateHostsFile = $true
    }

    if( -not $updateHostsFile )
    {
        return
    }
    
    Write-Verbose -Message ('[HOSTS]  [{0}]  {1,-45}  {2}' -f $Path,$IPAddress,$HostName)
    $outLines | Write-CFile -Path $Path
}


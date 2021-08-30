
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$ErrorActionPreference = 'Inquire'

function Expand-SqlLogFile{
    param(
    [string]$InstanceName = 'localhost',
    [parameter(Mandatory=$true)][string] $DatabaseName,
    [parameter(Mandatory=$true)][int] $LogSizeMB)
    
    [int]$LogFileSize = $LogSizeMB*1024
    
    
    $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $InstanceName
    $logfile = $srv.Databases[$DatabaseName].LogFiles[0]
    $CurrSize = $logfile.Size
    
    
    while($CurrSize -lt $LogFileSize){
        if(($LogFileSize - $CurrSize) -lt 8192000){$CurrSize = $LogFileSize}
        else{$CurrSize += 8192000}

        $logfile.size = $CurrSize
        $logfile.Alter()
    }
}


Expand-SqlLogFile -DatabaseName 'test' -LogSizeMB 35000
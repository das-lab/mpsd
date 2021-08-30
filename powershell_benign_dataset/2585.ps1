


[string] $script:filename = "E:\Dexma\EnumSqlServer\EnumSqlServer.html";
[bool]   $script:checkServices = $true;
[bool]   $script:getServerInfo = $true;


[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');

[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');



Add-Type @"
public struct SqlServerInstance {
   public string Name;
   public string Server;
   public string Instance;
   public bool IsClustered;
   public string Version;
   public bool IsLocal;
   public string IpAddress;
   public object[] Services;
   public object ServerInfo;
}
"@;

Add-Type @"
public struct ServiceInfo {
   public string Name;
   public string Caption;
   public string StartMode;
   public bool Started;
   public string State;
   public string Status;
   public string StartName;   
}
"@;

Add-Type @"
public struct SmoServerInfo {
   public string Edition;
   public string EngineEdition;
   public string ErrorLogPath;
   public string FilestreamShareName;
   public string RootDirectory;
   public string InstallDataDirectory;
   public string InstallSharedDirectory;
   public string Language;
   public string MasterDBPath;
   public string MasterDBLogPath;
   public string TcpEnabled;
   public string Version;
   public object[] Databases;
}
"@;

Add-Type @"
public struct DatabaseInfo {
   public string Name;
   public string Status;
   public string RecoveryModel;
   public double Size;
   public double SpaceAvailable;
   public string LastBackup;
}
"@;


function getIpAddress
{
    param([string] $server)
    
    [string] $addr = "no result";
    $ping = New-Object Net.NetworkInformation.Ping;
    try
    {
        $reply = $ping.Send($server);
        $addr = $reply.Address;
    }
    catch
    {   $addr = "Error while fetching address";    }
    
    $ping.Dispose();
    return $addr;
}

function getServiceInfo
{
    param([string] $server, [string] $service)

    try
    {
        $srvc = Get-WmiObject `
                    -query "SELECT * 
                            FROM win32_service 
                            WHERE name = '$service'" `
                    -computername $server `
                    -ErrorAction Stop;
        if ($srvc -ne $null)
        {
            [ServiceInfo] $info = New-Object "ServiceInfo";
            $info.Name = $srvc.Name;
            $info.Caption = $srvc.Caption;
            $info.Started = $srvc.Started;
            $info.StartMode = $srvc.StartMode;
            $info.State = $srvc.State;
            $info.Status = $srvc.Status;
            $info.StartName = $srvc.StartName;
            
            return $info;
        }
    }
    catch
    {   Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Error fetching service info over WMI from $server") -ForegroundColor Red;   }
}                 

function getServicesInfo
{
    param([string] $server, [string] $instance)
    
    [ServiceInfo[]] $services = @();
    
    
    
    if ((getServiceInfo $server ("PlugPlay")) -eq $null)
    {   return;   }
    
    Write-Host ((Get-Date -format  yyyy-MM-ddTHH:mm:ss) + ": Fetching services from " + $server);
    
    if (($info = (getServiceInfo $server ("MsDtsServer"))) -ne $null)
    {   $services += $info;    }
    if (($info = (getServiceInfo $server ("MSSQLServerADHelper"))) -ne $null)
    {   $services += $info;    }    
    if (($info = (getServiceInfo $server ("MSSQLServerADHelper100"))) -ne $null)
    {   $services += $info;    }        
    if (($info = (getServiceInfo $server ("SQLBrowser"))) -ne $null)
    {   $services += $info;    }
    if (($info = (getServiceInfo $server ("SQLWriter"))) -ne $null)
    {   $services += $info;    }

    
    if (($info = (getServiceInfo $server ("MSSQL$" + $instance))) -ne $null)
    {   $services += $info;    }
    if (($info = (getServiceInfo $server ("SQLAgent$" + $instance))) -ne $null)
    {   $services += $info;    }
    if (($info = (getServiceInfo $server ("msftesql$" + $instance))) -ne $null)
    {   $services += $info;    } 
    if (($info = (getServiceInfo $server ("MSSQLFDLauncher$" + $instance))) -ne $null)
    {   $services += $info;    }     
    if (($info = (getServiceInfo $server ("MSOLAP$" + $instance))) -ne $null)
    {   $services += $info;    }
    if (($info = (getServiceInfo $server ("ReportServer$" + $instance))) -ne $null)
    {   $services += $info;    }    
    
    return $services;
}

function getServerInfo
{
    param([string] $instanceName)
    
    try
    {
        Write-Host ((Get-Date -format  yyyy-MM-ddTHH:mm:ss) + ": Fetching smo infos from $instanceName");
        $smoSrv = New-Object Microsoft.SqlServer.Management.Smo.Server $instanceName;
      
        [SmoServerInfo] $smoInfo = New-Object "SmoServerInfo";
        $smoInfo.Edition = $smoSrv.Edition;
        
        if ($smoInfo.Edition -ne [string]::Empty)
        {
            $smoInfo.EngineEdition = $smoSrv.EngineEdition;
            $smoInfo.ErrorLogPath = $smoSrv.ErrorLogPath;
            $smoInfo.FilestreamShareName = $smoSrv.FilestreamShareName;
            $smoInfo.RootDirectory = $smoSrv.RootDirectory;
            $smoInfo.InstallDataDirectory = $smoSrv.InstallDataDirectory;
            $smoInfo.InstallSharedDirectory = $smoSrv.InstallSharedDirectory;
            $smoInfo.Language = $smoSrv.Language;
            $smoInfo.MasterDBPath = $smoSrv.MasterDBPath;
            $smoInfo.MasterDBLogPath = $smoSrv.MasterDBLogPath;
            $smoInfo.TcpEnabled = $smoSrv.TcpEnabled;
            $smoInfo.Version = $smoSrv.Version.ToString();
            
            foreach ($db in $smoSrv.Databases)
            {
                [DatabaseInfo] $dbInfo = New-Object DatabaseInfo;
                $dbInfo.Name = $db.Name;
                $dbInfo.RecoveryModel = $db.RecoveryModel;
                $dbInfo.Status = $db.Status;
                $dbInfo.Size = [Math]::Round($db.Size, 1);
                $dbInfo.SpaceAvailable = [Math]::Round($db.SpaceAvailable / 1024.0, 1);
                if ($db.LastBackupDate -ne [DateTime]::MinValue)
                {   $dbInfo.LastBackup = $db.LastBackupDate;   }
                
                $smoInfo.Databases += $dbInfo;
            }
            
            return $smoInfo;
        } 
    }
    catch
    {   Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Error fetching server info over SMO from $instanceName") -ForegroundColor Red;   }
}

function getHtmlPageHeader
{
    return `
    "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.0 Transitional//EN""><html><head>
    <title>Documentation of SQL Server Instances in the Local Network</title>
    <link rel=""stylesheet"" type=""text/css"" href=""EnumSqlServer.css""></link></head><body>
    <table class=""docTable"">
    <tr><td class=""docHeader"">Documentation of SQL Server Instances in the Local Network<br><br></td>
    </tr><tr><td>Document Created: " + (Get-Date -Format yyyy-MM-dd) + "</td></tr></table><br>"
}

function getHtmlParagraph1
{
    param([string] $text)
    return "<br><br><p class=""styleHeader1"">$text</p>";
}

function getHtmlParagraph2
{
    param([string] $text)
    return "<br><br><p class=""styleHeader2"">$text</p>";
}

function getHtmlTableStart
{
    param([string[]] $cols)
    [string] $tbl = "<table class=""styleTable""><colgroup>";
    [string] $tr  = "<tr>";
    
    foreach ($col in $cols)
    {
        $tbl += "<col></col>";
        $tr  += "<th class=""styleColHeader""><span>$col</span></th>";
    }
    
    return $tbl + "</colgroup>" + $tr + "</tr>";
}

function getHtmlTableAddRow
{
    param([string[]] $cols)
    [string] $tr  = "<tr>";
    
    foreach ($col in $cols)
    {   $tr  += "<th class=""styleCol""><span>$col</span></th>";    }
    
    return $tr + "</tr>";
}

function getHtmlTableEnd
{   return "</table>";   }






[SqlServerInstance[]] $servers = @();
Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Started enumerating SQL Server; this could take a while ...");
[Data.DataTable] $table = [Microsoft.SqlServer.Management.Smo.SmoApplication]::EnumAvailableSqlServers($false);
Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": " + $table.Rows.Count.ToString() + " server found.");
foreach ($row in $table)
{    
    [SqlServerInstance] $srv = New-Object "SqlServerInstance";
    $srv.Name = $row.Item("Name").ToString();
    $srv.Server = $row.Item("Server").ToString();
    $srv.Instance = $row.Item("Instance").ToString();
    if ($srv.Instance -eq [string]::Empty)   
    {   $srv.Instance = "MSSQLSERVER";   }
    Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Fetching infos from " + $srv.Name);
    $srv.IsClustered = $row.Item("IsClustered");
    $srv.Version = $row.Item("Version").ToString();
    $srv.IsLocal = $row.Item("IsLocal");
    $srv.IpAddress = getIpAddress $srv.Server;
    if ($script:checkServices -eq $true)
    {  $srv.Services = getServicesInfo  $srv.Server $srv.Instance; }
    if ($script:getServerInfo -eq $true)
    {  $srv.ServerInfo = getServerInfo  $srv.Name; }
    
    $servers += $srv;
}


Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Started creating Html document.");

$sb = New-Object System.Text.StringBuilder "";
$sb.Append( (getHtmlPageHeader) ) | Out-Null;


$sb.AppendLine( (getHtmlParagraph1 "SQL Server Instances Overview") ) | Out-Null;
$sb.AppendLine( (getHtmlTableStart @("Name", "Ip Address", "Instance", "Version")) ) | Out-Null;
foreach ($entry in ($servers | Sort-Object Server, Instance))
{
    [string] $link = "<a href=""
    $sb.AppendLine( (getHtmlTableAddRow @($link, $entry.IpAddress, $entry.Instance, $entry.Version)) ) | Out-Null;
}
$sb.AppendLine( (getHtmlTableEnd) ) | Out-Null;


foreach ($entry in ($servers | Sort-Object Server, Instance))
{
    [string] $link = "<a name=""" + $entry.Name + """>" + $entry.Name + "</a>";
    $sb.AppendLine( (getHtmlParagraph1 $link) ) | Out-Null;
    
    
    if ($entry.ServerInfo -eq $null)
    {
        $sb.AppendLine( (getHtmlParagraph2 "No Details of SQL Server Database Engine available") ) | Out-Null;
    }
    else
    {
        $sb.AppendLine( (getHtmlParagraph2 "Details of SQL Server Database Engine") ) | Out-Null;
        $sb.AppendLine( (getHtmlTableStart @("Property", "Value")) ) | Out-Null;
        
        $sb.AppendLine( (getHtmlTableAddRow @("Edition", $entry.ServerInfo.Edition)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("EngineEdition", $entry.ServerInfo.EngineEdition)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("Language", $entry.ServerInfo.Language)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("TcpEnabled", $entry.ServerInfo.TcpEnabled)) ) | Out-Null;
        
        $sb.AppendLine( (getHtmlTableAddRow @("InstallSharedDirectory", $entry.ServerInfo.InstallSharedDirectory)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("InstallDataDirectory", $entry.ServerInfo.InstallDataDirectory)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("MasterDBPath", $entry.ServerInfo.MasterDBPath)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("MasterDBLogPath", $entry.ServerInfo.MasterDBLogPath)) ) | Out-Null;
        $sb.AppendLine( (getHtmlTableAddRow @("ErrorLogPath", $entry.ServerInfo.ErrorLogPath)) ) | Out-Null;
         
        $sb.AppendLine( (getHtmlTableEnd) ) | Out-Null;
    }
    
    
    $sb.AppendLine( (getHtmlParagraph2 "Services of the Instance") ) | Out-Null;
    if (($script:checkServices -eq $true) -and ($entry.Services -ne $null))
    {
        $sb.AppendLine( (getHtmlTableStart @("Name", "Caption", "StartMode", "Started", "State", "Status", "StartName")) ) | Out-Null;
        foreach ($srvc in ($entry.Services | Sort-Object Name))
        {
            $sb.AppendLine( (getHtmlTableAddRow @($srvc.Name, $srvc.Caption, $srvc.StartMode, $srvc.Started, $srvc.State, $srvc.Status, $srvc.StartName)) ) | Out-Null;
        }
        
        $sb.AppendLine( (getHtmlTableEnd) ) | Out-Null;
    }
    
    
    if ($entry.ServerInfo.Databases -ne $null)
        {
            $sb.AppendLine( (getHtmlParagraph2 "Databases") ) | Out-Null;
            $sb.AppendLine( (getHtmlTableStart @("Name", "R-Model", "Status", "Size MB", "Available", "Last Backup")) ) | Out-Null;
            
            foreach ($dbEntry in ($entry.ServerInfo.Databases | Sort-Object Name))
            {
                $sb.AppendLine( (getHtmlTableAddRow @($dbEntry.Name, $dbEntry.RecoveryModel, $dbEntry.Status, $dbEntry.Size, $dbEntry.SpaceAvailable, $dbEntry.LastBackup)) ) | Out-Null;
            }
            
            $sb.AppendLine( (getHtmlTableEnd) ) | Out-Null;
        }
}

$sb.Append("</body></html>") | Out-Null;
Set-Content $filename $sb.ToString();

Write-Host ((Get-Date -format yyyy-MM-ddTHH:mm:ss) + ": Finished");
Invoke-Item $filename;




$server = "XSQLUTIL18"
$database = "master"
$query = "
SELECT	[sys].[tables].[name]
	  , [sys].[tables].[create_date]
	  , [sys].[tables].[modify_date]
FROM	sys.tables

SELECT	[sys].[columns].[name]
	  , [sys].[columns].[max_length]
	  , [sys].[columns].[precision]
	  , [sys].[columns].[scale]
FROM	sys.columns

SELECT	[sys].[indexes].[name]
	  , [sys].[indexes].[type_desc]
FROM	sys.indexes

SELECT	[sys].[databases].[name]
	  , [sys].[databases].[create_date]
	  , [sys].[databases].[compatibility_level]
	  , [sys].[databases].[collation_name]
FROM	sys.databases

SELECT	[sys].[database_files].[file_id]
	  , [sys].[database_files].[file_guid]
	  , [sys].[database_files].[type]
	  , [sys].[database_files].[type_desc]
	  , [sys].[database_files].[data_space_id]
	  , [sys].[database_files].[name]
	  , [sys].[database_files].[physical_name]
	  , [sys].[database_files].[state]
	  , [sys].[database_files].[state_desc]
	  , [sys].[database_files].[size]
	  , [sys].[database_files].[max_size]
	  , [sys].[database_files].[growth]
FROM	sys.database_files
"


$connectionTemplate = "Data Source={0};Integrated Security=SSPI;Initial Catalog={1};"
$connectionString = [string]::Format($connectionTemplate, $server, $database)
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$command = New-Object System.Data.SqlClient.SqlCommand
$command.CommandText = $query
$command.Connection = $connection

$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $command
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$connection.Close()

$excel = new-object -comobject excel.application
$excel.visible = $false
$workbook = $excel.workbooks.add()

for($i=4; $i -ge 0; $i--)
	{
	switch ($i) 
		{
			"0"	{ 	$extractFile 	= 	"E:\Dexma\AHMSIReports\Tables.csv"; 
					$TabName		=	"Tables";
					$Columns		=	"C";}
			"1"	{ 	$extractFile 	= 	"E:\Dexma\AHMSIReports\Columns.csv";  
					$TabName		=	"Columns";
					$Columns		=	"C";}
			"2"	{ 	$extractFile 	= 	"E:\Dexma\AHMSIReports\Indexes.csv"; 
					$TabName		=	"Indexes";
					$Columns		=	"B";}
			"3"	{ 	$extractFile 	= 	"E:\Dexma\AHMSIReports\Databases.csv"; 
					$TabName		=	"Databases";
					$Columns		=	"D";}
			"4"	{ 	$extractFile 	= 	"E:\Dexma\AHMSIReports\DatabaseFiles.csv";  
					$TabName		=	"DatabaseFiles";
					$Columns		=	"L";}
		}

	
	
	$csvResults = $DataSet.Tables[$i] | ConvertTo-CSV -Delimiter "`t" -NoTypeInformation
	$csvResults | Out-Clipboard
	
	$Worksheet = $Workbook.Sheets.Add()
    $Worksheet.Name = $TabName
    $Range = $Worksheet.Range("a1","$Columns$($csvResults.count)")
    $Worksheet.Paste($Range, $false)
 
    
    
    
    $Range.EntireColumn.Autofit()
	}


$Excel.DisplayAlerts = $false
$Workbook.Worksheets.Item("Sheet1").Delete()
$Workbook.Worksheets.Item("Sheet2").Delete()
$Workbook.Worksheets.Item("Sheet3").Delete()
 
$Workbook.SaveAs("E:\Dexma\AHMSIReports\AHMSIReport.xlsx")
function Get-ComputerDetails
{


    Param(
        [Parameter(Position=0)]
        [Switch]
        $ToString
    )

    Set-StrictMode -Version 2



    $SecurityLog = Get-EventLog -LogName Security
    $Filtered4624 = Find-4624Logons $SecurityLog
    $Filtered4648 = Find-4648Logons $SecurityLog
    $AppLockerLogs = Find-AppLockerLogs
    $PSLogs = Find-PSScriptsInPSAppLog
    $RdpClientData = Find-RDPClientConnections

    if ($ToString)
    {
        Write-Output "Event ID 4624 (Logon):"
        Write-Output $Filtered4624.Values | Format-List
        Write-Output "Event ID 4648 (Explicit Credential Logon):"
        Write-Output $Filtered4648.Values | Format-List
        Write-Output "AppLocker Process Starts:"
        Write-Output $AppLockerLogs.Values | Format-List
        Write-Output "PowerShell Script Executions:"
        Write-Output $PSLogs.Values | Format-List
        Write-Output "RDP Client Data:"
        Write-Output $RdpClientData.Values | Format-List
    }
    else
    {
        $Properties = @{
            LogonEvent4624 = $Filtered4624.Values
            LogonEvent4648 = $Filtered4648.Values
            AppLockerProcessStart = $AppLockerLogs.Values
            PowerShellScriptStart = $PSLogs.Values
            RdpClientData = $RdpClientData.Values
        }

        $ReturnObj = New-Object PSObject -Property $Properties
        return $ReturnObj
    }
}


function Find-4648Logons
{

    Param(
        $SecurityLog
    )

    $ExplicitLogons = $SecurityLog | Where {$_.InstanceID -eq 4648}
    $ReturnInfo = @{}

    foreach ($ExplicitLogon in $ExplicitLogons)
    {
        $Subject = $false
        $AccountWhosCredsUsed = $false
        $TargetServer = $false
        $SourceAccountName = ""
        $SourceAccountDomain = ""
        $TargetAccountName = ""
        $TargetAccountDomain = ""
        $TargetServer = ""
        foreach ($line in $ExplicitLogon.Message -split "\r\n")
        {
            if ($line -cmatch "^Subject:$")
            {
                $Subject = $true
            }
            elseif ($line -cmatch "^Account\sWhose\sCredentials\sWere\sUsed:$")
            {
                $Subject = $false
                $AccountWhosCredsUsed = $true
            }
            elseif ($line -cmatch "^Target\sServer:")
            {
                $AccountWhosCredsUsed = $false
                $TargetServer = $true
            }
            elseif ($Subject -eq $true)
            {
                if ($line -cmatch "\s+Account\sName:\s+(\S.*)")
                {
                    $SourceAccountName = $Matches[1]
                }
                elseif ($line -cmatch "\s+Account\sDomain:\s+(\S.*)")
                {
                    $SourceAccountDomain = $Matches[1]
                }
            }
            elseif ($AccountWhosCredsUsed -eq $true)
            {
                if ($line -cmatch "\s+Account\sName:\s+(\S.*)")
                {
                    $TargetAccountName = $Matches[1]
                }
                elseif ($line -cmatch "\s+Account\sDomain:\s+(\S.*)")
                {
                    $TargetAccountDomain = $Matches[1]
                }
            }
            elseif ($TargetServer -eq $true)
            {
                if ($line -cmatch "\s+Target\sServer\sName:\s+(\S.*)")
                {
                    $TargetServer = $Matches[1]
                }
            }
        }

        
        if (-not ($TargetAccountName -cmatch "^DWM-.*" -and $TargetAccountDomain -cmatch "^Window\sManager$"))
        {
            $Key = $SourceAccountName + $SourceAccountDomain + $TargetAccountName + $TargetAccountDomain + $TargetServer
            if (-not $ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    LogType = 4648
                    LogSource = "Security"
                    SourceAccountName = $SourceAccountName
                    SourceDomainName = $SourceAccountDomain
                    TargetAccountName = $TargetAccountName
                    TargetDomainName = $TargetAccountDomain
                    TargetServer = $TargetServer
                    Count = 1
                    Times = @($ExplicitLogon.TimeGenerated)
                }

                $ResultObj = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $ResultObj)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                $ReturnInfo[$Key].Times += ,$ExplicitLogon.TimeGenerated
            }
        }
    }

    return $ReturnInfo
}

function Find-4624Logons
{

    Param (
        $SecurityLog
    )

    $Logons = $SecurityLog | Where {$_.InstanceID -eq 4624}
    $ReturnInfo = @{}

    foreach ($Logon in $Logons)
    {
        $SubjectSection = $false
        $NewLogonSection = $false
        $NetworkInformationSection = $false
        $AccountName = ""
        $AccountDomain = ""
        $LogonType = ""
        $NewLogonAccountName = ""
        $NewLogonAccountDomain = ""
        $WorkstationName = ""
        $SourceNetworkAddress = ""
        $SourcePort = ""

        foreach ($line in $Logon.Message -Split "\r\n")
        {
            if ($line -cmatch "^Subject:$")
            {
                $SubjectSection = $true
            }
            elseif ($line -cmatch "^Logon\sType:\s+(\S.*)")
            {
                $LogonType = $Matches[1]
            }
            elseif ($line -cmatch "^New\sLogon:$")
            {
                $SubjectSection = $false
                $NewLogonSection = $true
            }
            elseif ($line -cmatch "^Network\sInformation:$")
            {
                $NewLogonSection = $false
                $NetworkInformationSection = $true
            }
            elseif ($SubjectSection)
            {
                if ($line -cmatch "^\s+Account\sName:\s+(\S.*)")
                {
                    $AccountName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Account\sDomain:\s+(\S.*)")
                {
                    $AccountDomain = $Matches[1]
                }
            }
            elseif ($NewLogonSection)
            {
                if ($line -cmatch "^\s+Account\sName:\s+(\S.*)")
                {
                    $NewLogonAccountName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Account\sDomain:\s+(\S.*)")
                {
                    $NewLogonAccountDomain = $Matches[1]
                }
            }
            elseif ($NetworkInformationSection)
            {
                if ($line -cmatch "^\s+Workstation\sName:\s+(\S.*)")
                {
                    $WorkstationName = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Source\sNetwork\sAddress:\s+(\S.*)")
                {
                    $SourceNetworkAddress = $Matches[1]
                }
                elseif ($line -cmatch "^\s+Source\sPort:\s+(\S.*)")
                {
                    $SourcePort = $Matches[1]
                }
            }
        }

        
        if (-not ($NewLogonAccountDomain -cmatch "NT\sAUTHORITY" -or $NewLogonAccountDomain -cmatch "Window\sManager"))
        {
            $Key = $AccountName + $AccountDomain + $NewLogonAccountName + $NewLogonAccountDomain + $LogonType + $WorkstationName + $SourceNetworkAddress + $SourcePort
            if (-not $ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    LogType = 4624
                    LogSource = "Security"
                    SourceAccountName = $AccountName
                    SourceDomainName = $AccountDomain
                    NewLogonAccountName = $NewLogonAccountName
                    NewLogonAccountDomain = $NewLogonAccountDomain
                    LogonType = $LogonType
                    WorkstationName = $WorkstationName
                    SourceNetworkAddress = $SourceNetworkAddress
                    SourcePort = $SourcePort
                    Count = 1
                    Times = @($Logon.TimeGenerated)
                }

                $ResultObj = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $ResultObj)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                $ReturnInfo[$Key].Times += ,$Logon.TimeGenerated
            }
        }
    }

    return $ReturnInfo
}


function Find-AppLockerLogs
{

    $ReturnInfo = @{}

    $AppLockerLogs = Get-WinEvent -LogName "Microsoft-Windows-AppLocker/EXE and DLL" -ErrorAction SilentlyContinue | Where {$_.Id -eq 8002}

    foreach ($Log in $AppLockerLogs)
    {
        $SID = New-Object System.Security.Principal.SecurityIdentifier($Log.Properties[7].Value)
        $UserName = $SID.Translate( [System.Security.Principal.NTAccount])

        $ExeName = $Log.Properties[10].Value

        $Key = $UserName.ToString() + "::::" + $ExeName

        if (!$ReturnInfo.ContainsKey($Key))
        {
            $Properties = @{
                Exe = $ExeName
                User = $UserName.Value
                Count = 1
                Times = @($Log.TimeCreated)
            }

            $Item = New-Object PSObject -Property $Properties
            $ReturnInfo.Add($Key, $Item)
        }
        else
        {
            $ReturnInfo[$Key].Count++
            $ReturnInfo[$Key].Times += ,$Log.TimeCreated
        }
    }

    return $ReturnInfo
}


Function Find-PSScriptsInPSAppLog
{

    $ReturnInfo = @{}
    $Logs = Get-WinEvent -LogName "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue | Where {$_.Id -eq 4100}

    foreach ($Log in $Logs)
    {
        $ContainsScriptName = $false
        $LogDetails = $Log.Message -split "`r`n"

        $FoundScriptName = $false
        foreach($Line in $LogDetails)
        {
            if ($Line -imatch "^\s*Script\sName\s=\s(.+)")
            {
                $ScriptName = $Matches[1]
                $FoundScriptName = $true
            }
            elseif ($Line -imatch "^\s*User\s=\s(.*)")
            {
                $User = $Matches[1]
            }
        }

        if ($FoundScriptName)
        {
            $Key = $ScriptName + "::::" + $User

            if (!$ReturnInfo.ContainsKey($Key))
            {
                $Properties = @{
                    ScriptName = $ScriptName
                    UserName = $User
                    Count = 1
                    Times = @($Log.TimeCreated)
                }

                $Item = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $Item)
            }
            else
            {
                $ReturnInfo[$Key].Count++
                $ReturnInfo[$Key].Times += ,$Log.TimeCreated
            }
        }
    }

    return $ReturnInfo
}


Function Find-RDPClientConnections
{

    $ReturnInfo = @{}

    New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS | Out-Null

    
    $Users = Get-ChildItem -Path "HKU:\"
    foreach ($UserSid in $Users.PSChildName)
    {
        $Servers = Get-ChildItem "HKU:\$($UserSid)\Software\Microsoft\Terminal Server Client\Servers" -ErrorAction SilentlyContinue

        foreach ($Server in $Servers)
        {
            $Server = $Server.PSChildName
            $UsernameHint = (Get-ItemProperty -Path "HKU:\$($UserSid)\Software\Microsoft\Terminal Server Client\Servers\$($Server)").UsernameHint
                
            $Key = $UserSid + "::::" + $Server + "::::" + $UsernameHint

            if (!$ReturnInfo.ContainsKey($Key))
            {
                $SIDObj = New-Object System.Security.Principal.SecurityIdentifier($UserSid)
                $User = ($SIDObj.Translate([System.Security.Principal.NTAccount])).Value

                $Properties = @{
                    CurrentUser = $User
                    Server = $Server
                    UsernameHint = $UsernameHint
                }

                $Item = New-Object PSObject -Property $Properties
                $ReturnInfo.Add($Key, $Item)
            }
        }
    }

    return $ReturnInfo
}

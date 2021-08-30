
function New-PoshBotScheduledTask {
    
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string]$Name = 'PoshBot',

        [string]$Description = 'Start PoshBot',

        [parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_) {
                if ( (Get-Item -Path $_).Extension -eq '.psd1') {
                    $true
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Throw 'Path is not valid'
            }
        })]
        [string]$Path,

        [parameter(Mandatory)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [switch]$PassThru,

        [switch]$Force
    )

    if ($Force -or (-not (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue))) {
        if ($PSCmdlet.ShouldProcess($Name, 'Created PoshBot scheduled task')) {

            $taskParams = @{
                Description = $Description
            }

            
            
            
            
            $startScript = Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Task\StartPoshBot.ps1')

            
            $arg = "& '$startScript' -Path '$Path'"
            $actionParams = @{
                Execute = "$($env:SystemDrive)\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                Argument = '-ExecutionPolicy Bypass -NonInteractive -Command "' + $arg + '"'
                WorkingDirectory = $PSScriptRoot
            }
            $taskParams.Action = New-ScheduledTaskAction @actionParams

            
            $taskParams.Trigger = New-ScheduledTaskTrigger -AtStartup

            
            $settingsParams = @{
                AllowStartIfOnBatteries = $true
                DontStopIfGoingOnBatteries = $true
                ExecutionTimeLimit = 0
                RestartCount = 999
                RestartInterval = (New-TimeSpan -Minutes 1)
            }
            $taskParams.Settings = New-ScheduledTaskSettingsSet @settingsParams

            
            $registerParams = @{
                TaskName = $Name
                Force = $true
            }
            
            $registerParams.User = $Credential.UserName
            $registerParams.Password = $Credential.GetNetworkCredential().Password
            $task = New-ScheduledTask @taskParams
            $newTask = Register-ScheduledTask -InputObject $task @registerParams
            if ($PassThru) {
                $newTask
            }
        }
    } else {
        Write-Error -Message "Existing task named [$Name] found. To overwrite, use the -Force"
    }
}

Export-ModuleMember -Function 'New-PoshBotScheduledTask'

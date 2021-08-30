


$powershell = Join-Path -Path $PsHome -ChildPath "pwsh"

function Wait-JobPid {
    param (
        $Job
    )

    
    $startTime = [DateTime]::Now
    $TimeoutInMilliseconds = 10000

    
    do {
        Start-Sleep -Seconds 1
        $pwshId = Receive-Job $Job

        if (([DateTime]::Now - $startTime).TotalMilliseconds -gt $timeoutInMilliseconds) {
            throw "Unable to receive PowerShell process id."
        }
    } while (!$pwshId)

    $pwshId
}


function Invoke-PSHostProcessScript {
    param (
        [string] $ArgumentString,
        [int] $Id,
        [int] $Retry = 5 
    )

    $sb = {
        
        
        $commandStr = @'
Start-Sleep -Seconds {0}
Enter-PSHostProcess {1} -ErrorAction Stop
$pid
Exit-PSHostProcess
'@ -f $i, $ArgumentString

        ($commandStr | & $powershell -c -) -eq $Id
    }

    $result = $false
    $failures = 0
    foreach ($i in 1..$Retry) {
        if ($sb.Invoke()) {
            $result = $true
            break
        }

        $failures++
    }

    if($failures) {
        Write-Warning "Enter-PSHostProcess script failed $i out of $Retry times."
    }

    $result
}

Describe "Enter-PSHostProcess tests" -Tag Feature {
    Context "By Process Id" {

        BeforeEach {
            
            
            $pwshJob = Start-Job {
                $pid
                while ($true) {
                    Start-Sleep -Seconds 30 | Out-Null
                }
            }

            $pwshId = Wait-JobPid $pwshJob
        }

        AfterEach {
            $pwshJob | Stop-Job -PassThru | Remove-Job
        }

        It "Can enter, exit, and re-enter another PSHost" {
            Wait-UntilTrue { [bool](Get-PSHostProcessInfo -Id $pwshId) } | Should -BeTrue

            
            Invoke-PSHostProcessScript -ArgumentString "-Id $pwshId" -Id $pwshId |
                Should -BeTrue -Because "The script was able to enter another process and grab the pid of '$pwshId'."

            
            Invoke-PSHostProcessScript -ArgumentString "-Id $pwshId" -Id $pwshId |
                Should -BeTrue -Because "The script was able to re-enter another process and grab the pid of '$pwshId'."
        }

        It "Can enter, exit, and re-enter another Windows PowerShell PSHost" -Skip:(!$IsWindows) {
            
            
            $powershellJob = Start-Job -PSVersion 5.1 {
                $pid
                while ($true) {
                    Start-Sleep -Seconds 30 | Out-Null
                }
            }

            $powershellId = Wait-JobPid $powershellJob

            try {
                Wait-UntilTrue { [bool](Get-PSHostProcessInfo -Id $powershellId) } | Should -BeTrue

                
                Invoke-PSHostProcessScript -ArgumentString "-Id $powershellId" -Id $powershellId |
                    Should -BeTrue -Because "The script was able to enter another process and grab the pid of '$powershellId'."

                
                Invoke-PSHostProcessScript -ArgumentString "-Id $powershellId" -Id $powershellId |
                    Should -BeTrue -Because "The script was able to re-enter another process and grab the pid of '$powershellId'."

            } finally {
                $powershellJob | Stop-Job -PassThru | Remove-Job
            }
        }

        It "Can enter using NamedPipeConnectionInfo" {
            try {
                Wait-UntilTrue { [bool](Get-PSHostProcessInfo -Id $pwshId) } | Should -BeTrue

                $npInfo = [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new($pwshId)
                $rs = [runspacefactory]::CreateRunspace($npInfo)
                $rs.Open()
                $ps = [powershell]::Create()
                $ps.Runspace = $rs
                $ps.AddScript('$pid').Invoke() | Should -Be $pwshId
            } finally {
                $rs.Dispose()
                $ps.Dispose()
            }
        }
    }

    Context "By CustomPipeName" {

        It "Can enter, exit, and re-enter using CustomPipeName" {
            $pipeName = [System.IO.Path]::GetRandomFileName()
            $pipePath = Get-PipePath -PipeName $pipeName

            
            
            
            $pwshJob = Start-Job -ArgumentList $pipeName {
                [System.Management.Automation.Remoting.RemoteSessionNamedPipeServer]::CreateCustomNamedPipeServer($args[0])
                $pid
                while ($true) { Start-Sleep -Seconds 30 | Out-Null }
            }

            $pwshId = Wait-JobPid $pwshJob

            try {
                Wait-UntilTrue { Test-Path $pipePath } | Should -BeTrue

                
                Invoke-PSHostProcessScript -ArgumentString "-CustomPipeName $pipeName" -Id $pwshId |
                    Should -BeTrue -Because "The script was able to enter another process and grab the pipe of '$pipeName'."

                
                Invoke-PSHostProcessScript -ArgumentString "-CustomPipeName $pipeName" -Id $pwshId |
                    Should -BeTrue -Because "The script was able to re-enter another process and grab the pipe of '$pipeName'."

            } finally {
                $pwshJob | Stop-Job -PassThru | Remove-Job
            }
        }

        It "Should throw if CustomPipeName does not exist" {
            { Enter-PSHostProcess -CustomPipeName badpipename } | Should -Throw -ExpectedMessage "No named pipe was found with CustomPipeName: badpipename."
        }
    }
}





$restartTesthookName = "TestStopComputer"
$restartTesthookResultName = "TestStopComputerResults"
$DefaultResultValue = 0

try
{
    
    $PSDefaultParameterValues["it:skip"] = ! $IsWindows
    Enable-Testhook -testhookName $restartTesthookName

    Describe "Restart-Computer" -Tag Feature,RequireAdminOnWindows {
        
        BeforeEach {
            if ( ! (Test-TesthookIsSet -testhookName $restartTesthookName) ) {
                throw "Testhook '${restartTesthookName}' is not set"
            }
        }

        AfterEach {
            Set-TesthookResult -testhookName $restartTesthookResultName -value $defaultResultValue
        }

        It "Should restart the local computer" {
            Set-TesthookResult -testhookName $restartTesthookResultName -value $defaultResultValue
            Restart-Computer -ErrorAction Stop| Should -BeNullOrEmpty
        }

        It "Should support -computer parameter" {
            Set-TesthookResult -testhookName $restartTesthookResultName -value $defaultResultValue
            $computerNames = "localhost","${env:COMPUTERNAME}"
            Restart-Computer -Computer $computerNames -ErrorAction Stop| Should -BeNullOrEmpty
        }

        It "Should support WsmanAuthentication types" {
            $authChoices = "Default","Basic","Negotiate","CredSSP","Digest","Kerberos"
            foreach ( $auth in $authChoices ) {
                Restart-Computer -WsmanAuthentication $auth | Should -BeNullOrEmpty
            }
        }

        
        
        
        It "Should wait for a remote system" {
            try
            {
                Enable-Testhook -testhookname TestWaitStopComputer
                $timeout = 3
                try
                {
                    $pPref = $ProgressPreference
                    $ProgressPreference="SilentlyContinue"
                    $duration = Measure-Command {
                        Restart-Computer -computer localhost -Wait -Timeout $timeout -ErrorAction Stop | Should -BeNullOrEmpty
                    }
                }
                finally
                {
                    $ProgressPreference=$pPref
                }
                $duration.TotalSeconds | Should -BeGreaterThan $timeout
            }
            finally
            {
                Disable-Testhook -testhookname TestWaitStopComputer
            }
        }

        Context "Restart-Computer Error Conditions" {
            It "Should return the proper error when it occurs" {
                Set-TesthookResult -testhookName $restartTesthookResultName -value 0x300000
                Restart-Computer -ErrorVariable RestartError 2> $null
                $RestartError.Exception.Message | Should -Match 0x300000
            }

            It "Should produce an error when 'Delay' is specified" {
                { Restart-Computer -Delay 30 } | Should -Throw -ErrorId "RestartComputerInvalidParameter,Microsoft.PowerShell.Commands.RestartComputerCommand"
            }

            It "Should not support timeout on localhost" {
                Set-TesthookResult -testhookName $restartTesthookResultName -value $defaultResultValue
                { Restart-Computer -timeout 3 -ErrorAction Stop } | Should -Throw -ErrorId "RestartComputerInvalidParameter,Microsoft.PowerShell.Commands.RestartComputerCommand"
            }

            It "Should not support timeout on localhost" {
                Set-TesthookResult -testhookName $restartTesthookResultName -value $defaultResultValue
                { Restart-Computer -timeout 3 -ErrorAction Stop } | Should -Throw -ErrorId "RestartComputerInvalidParameter,Microsoft.PowerShell.Commands.RestartComputerCommand"
            }
        }
    }

}
finally
{
    $PSDefaultParameterValues.Remove("it:skip")
    Disable-Testhook -testhookName $restartTesthookName
    Set-TesthookResult -testhookName $restartTesthookResultName -value 0
}

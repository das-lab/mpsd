












Import-Module HelpersSecurity

try
{
    $defaultParamValues = $PSDefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:Skip"] = !$IsWindows

    Describe "Importing PowerShell script files are not allowed in ConstrainedLanguage" -Tags 'CI','RequireAdminOnWindows' {

        BeforeAll {

            $scriptFileName = (Get-RandomFileName) + ".ps1"
            $scriptFilePath = Join-Path $TestDrive $scriptFileName
            '"Hello!"' > $scriptFilePath
        }

        It "Verifies that ps1 script file cannot be imported in ConstrainedLanguage mode" {

            $err = $null
            try
            {
                $ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"
                Import-Module -Name $scriptFilePath
                throw "No Exception!"
            }
            catch
            {
                $err = $_
            }
            finally
            {
                Invoke-LanguageModeTestingSupportCmdlet -EnableFullLanguageMode
            }

            $err.FullyQualifiedErrorId | Should -BeExactly "Modules_ImportPSFileNotAllowedInConstrainedLanguage,Microsoft.PowerShell.Commands.ImportModuleCommand"
        }

        It "Verifies that ps1 script file can be imported in FullLangauge mode" {

            { Import-Module -Name $scriptFilePath } | Should -Not -Throw
        }
    }

    Describe "Start-Job initialization script should work in system lock down" -Tags 'Feature','RequireAdminOnWindows' {

        It "Verifies that Start-Job initialization script runs successfully in system lock down" {

            try
            {
                Invoke-LanguageModeTestingSupportCmdlet -SetLockdownMode
                $ExecutionContext.SessionState.LanguageMode = "ConstrainedLanguage"

                $job = Start-Job -InitializationScript { function Hello { "Hello" } } -ScriptBlock { Hello }
                $result = $job | Wait-Job | Receive-Job
            }
            finally
            {
                Invoke-LanguageModeTestingSupportCmdlet -RevertLockdownMode -EnableFullLanguageMode
            }

            $result | Should -BeExactly "Hello"
            $job | Remove-Job
        }
    }

    
}
finally
{
    if ($defaultParamValues -ne $null)
    {
        $Global:PSDefaultParameterValues = $defaultParamValues
    }
}

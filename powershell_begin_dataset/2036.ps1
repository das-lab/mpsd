







try {
    
    $IsInbox = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase)
    $productName = "PowerShell"

    
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    $IsNotSkipped = ($IsWindows -and !$IsInbox) 
    $PSDefaultParameterValues["it:skip"] = !$IsNotSkipped

    Describe "User-Specific powershell.config.json Modifications" -Tags "CI" {

        BeforeAll {
            if ($IsNotSkipped) {
                
                $userSettingsDir = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", $productName)
                $userPropertiesFile = Join-Path $userSettingsDir "powershell.config.json"

                
                $backupPropertiesFile = ""
                if (Test-Path $userPropertiesFile) {
                    $backupPropertiesFile = Join-Path $userSettingsDir "ORIGINAL_powershell.config.json"
                    Copy-Item -Path $userPropertiesFile -Destination $backupPropertiesFile -Force -ErrorAction Continue
                }
                elseif (-not (Test-Path $userSettingsDir)) {
                    
                    $null = New-Item -Type Directory -Path $userSettingsDir -Force -ErrorAction SilentlyContinue
                }

                
                $processExecutionPolicy = Get-ExecutionPolicy -Scope Process
                Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined
            }
        }

        BeforeEach {
            if ($IsNotSkipped) {
                Set-Content -Path $userPropertiesFile -Value '{"Microsoft.PowerShell:ExecutionPolicy":"RemoteSigned"}'
            }
        }

        AfterAll {
            if ($IsNotSkipped) {
                if (-not $backupPropertiesFile)
                {
                    
                    Remove-Item -Path $userPropertiesFile -Force -ErrorAction SilentlyContinue
                }
                else
                {
                    
                    Move-Item -Path $backupPropertiesFile -Destination $userPropertiesFile -Force -ErrorAction Continue
                }

                
                Set-ExecutionPolicy -Scope Process -ExecutionPolicy $processExecutionPolicy
            }
        }

        It "Verify Queries to Missing File Return Default Value" {
            Remove-Item $userPropertiesFile -Force

            Get-ExecutionPolicy -Scope CurrentUser | Should -Be "Undefined"

            
            { $propFile = Get-Item $userPropertiesFile -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
        }

        It "Verify Queries for Non-Existant Properties Return Default Value" {
            
            Set-Content -Path $userPropertiesFile -Value "{}"

            Get-ExecutionPolicy -Scope CurrentUser | Should -Be "Undefined"
        }

        It "Verify Writes Update Properties" {
            Get-Content -Path $userPropertiesFile | Should -Be '{"Microsoft.PowerShell:ExecutionPolicy":"RemoteSigned"}'
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
            Get-Content -Path $userPropertiesFile | Should -Be '{"Microsoft.PowerShell:ExecutionPolicy":"Bypass"}'
        }

        It "Verify Writes Create the File if Not Present" {
            Remove-Item $userPropertiesFile -Force
            Test-Path $userPropertiesFile | Should -BeFalse
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass
            Get-Content -Path $userPropertiesFile | Should -Be '{"Microsoft.PowerShell:ExecutionPolicy":"Bypass"}'
        }
    }
}
finally {
    $global:PSDefaultParameterValues = $originalDefaultParameterValues
}

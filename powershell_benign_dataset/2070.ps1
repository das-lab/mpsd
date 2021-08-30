

Describe 'Online help tests for PowerShell Cmdlets' -Tags "CI" {

    
    
    
    

    BeforeAll {
        $SavedProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"

        
        
        
        [system.management.automation.internal.internaltesthooks]::SetTestHook('BypassOnlineHelpRetrieval', $true)
    }

    AfterAll {

        
        [system.management.automation.internal.internaltesthooks]::SetTestHook('BypassOnlineHelpRetrieval', $false)
        $ProgressPreference = $SavedProgressPreference
    }

    foreach ($filePath in @("$PSScriptRoot\assets\HelpURI\V2Cmdlets.csv", "$PSScriptRoot\assets\HelpURI\V3Cmdlets.csv"))
    {
        $cmdletList = Import-Csv $filePath -ErrorAction Stop

        foreach ($cmdlet in $cmdletList)
        {
            
            $skipTest = $null -eq (Get-Command $cmdlet.TopicTitle -ErrorAction SilentlyContinue)

            
            

            It "Validate 'get-help $($cmdlet.TopicTitle) -Online'" -Skip:$skipTest {
                $actualURI = Get-Help $cmdlet.TopicTitle -Online
                $actualURI = $actualURI.Replace("Help URI: ","")
                $actualURI | Should -Be $cmdlet.HelpURI
            }
        }
    }
}

Describe 'Get-Help -Online opens the default web browser and navigates to the cmdlet help content' -Tags "Feature" {

    $skipTest = [System.Management.Automation.Platform]::IsIoT -or
                [System.Management.Automation.Platform]::IsNanoServer -or
                $env:__INCONTAINER -eq 1

    
    if((-not ($skipTest)) -and $IsWindows)
    {
        $skipTest = $true
        $regKey = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice"

        try
        {
            $progId = (Get-ItemProperty $regKey).ProgId
            if($progId)
            {
                if (-not (Test-Path 'HKCR:\'))
                {
                    New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Should NotBeNullOrEmpty
                }
                $browserExe = ((Get-ItemProperty "HKCR:\$progId\shell\open\command")."(default)" -replace '"', '') -split " "
                if ($browserExe.count -ge 1)
                {
                    if($browserExe[0] -match '.exe')
                    {
                        $skipTest = $false
                    }
                }
            }
        }
        catch
        {
            
        }
    }

    It "Get-Help get-process -online" -skip:$skipTest {
        { Get-Help get-process -online } | Should -Not -Throw
    }
}

Describe 'Get-Help -Online is not supported on Nano Server and IoT' -Tags "CI" {

    $skipTest = -not ([System.Management.Automation.Platform]::IsIoT -or [System.Management.Automation.Platform]::IsNanoServer)

    It "Get-help -online <cmdletName> throws InvalidOperation." -skip:$skipTest {
        { Get-Help Get-Help -Online } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.GetHelpCommand"
    }
}

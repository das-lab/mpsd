











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-PathProvider' {
    
    It 'should get file system provider' {
        ((Get-PathProvider -Path 'C:\Windows').Name) | Should Be 'FileSystem'
    }
    
    It 'should get relative path provider' {
        ((Get-PathProvider -Path '..\').Name) | Should Be 'FileSystem'
    }
    
    It 'should get registry provider' {
        ((Get-PathProvider -Path 'hklm:\software').Name) | Should Be 'Registry'
    }
    
    It 'should get relative path provider' {
        Push-Location 'hklm:\SOFTWARE\Microsoft'
        try
        {
            ((Get-PathProvider -Path '..\').Name) | Should Be 'Registry'
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should get no provider for bad path' {
        ((Get-PathProvider -Path 'C:\I\Do\Not\Exist').Name) | Should Be 'FileSystem'
    }
    
}

Describe 'Get-PathProvider when passed a registry key PSPath' {
    It 'should return Registry' {
        Get-PathProvider -Path (Get-Item -Path 'hkcu:\software').PSPath | Select-Object -ExpandProperty 'Name' | Should Be 'Registry'
    }
}
function New-Fixture {
    

    param (
        [String]$Path = $PWD,
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $Name = $Name -replace '.ps1', ''

    
    
    $scriptCode = "function $Name {$([System.Environment]::NewLine)$([System.Environment]::NewLine)}"

    $testCode = '$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace ''\.Tests\.'', ''.''
. "$here\$sut"

Describe "
    It "does something useful" {
        $true | Should -Be $false
    }
}' -replace "

    

    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    Create-File -Path $Path -Name "$Name.ps1" -Content $scriptCode
    Create-File -Path $Path -Name "$Name.Tests.ps1" -Content $testCode
}

function Create-File ($Path, $Name, $Content) {
    if (-not (& $SafeCommands['Test-Path'] -Path $Path)) {
        & $SafeCommands['New-Item'] -ItemType Directory -Path $Path | & $SafeCommands['Out-Null']
    }

    $FullPath = & $SafeCommands['Join-Path'] -Path $Path -ChildPath $Name
    if (-not (& $SafeCommands['Test-Path'] -Path $FullPath)) {
        & $SafeCommands['Set-Content'] -Path  $FullPath -Value $Content -Encoding UTF8
        & $SafeCommands['Get-Item'] -Path $FullPath
    }
    else {
        
        
        
        Write-Warning "Skipping the file '$FullPath', because it already exists."
    }
}

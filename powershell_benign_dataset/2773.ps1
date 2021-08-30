


function Compute-FileHash {
Param(
    [Parameter(Mandatory = $true, Position=1)]
    [string]$FilePath,
    [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
    [string]$HashType = "MD5"
)
    
    switch ( $HashType.ToUpper() )
    {
        "MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
        "SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
        "SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
        "SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
        "SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
        "RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
        default     { "Invalid hash type selected." }
    }

    if (Test-Path $FilePath) {
        $File = Get-ChildItem -Force $FilePath
        $fileData = [System.IO.File]::ReadAllBytes($File.FullName)
        $HashBytes = $hash.ComputeHash($fileData)
        $PaddedHex = ""

        foreach($Byte in $HashBytes) {
            $ByteInHex = [String]::Format("{0:X}", $Byte)
            $PaddedHex += $ByteInHex.PadLeft(2,"0")
        }
        $PaddedHex
        $File.LastWriteTimeUtc
        $File.Length
        
    } else {
        "${FilePath} is locked or could not be found."
        "${FilePath} is locked or could not be not found."
        Write-Error -Category InvalidArgument -Message ("{0} is locked or could not be found." -f $FilePath)
    }
}

function GetShannonEntropy {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FilePath
)
    $fileEntropy = 0.0
    $FrequencyTable = @{}
    $ByteArrayLength = 0
            
    if(Test-Path $FilePath) {
        $file = (ls $FilePath)
        Try {
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        } Catch {
            Write-Error -Message ("Caught {0}." -f $_)
        }

        foreach($fileByte in $fileBytes) {
            $FrequencyTable[$fileByte]++
            $ByteArrayLength++
        }

        $byteMax = 255
        for($byte = 0; $byte -le $byteMax; $byte++) {
            $byteProb = ([double]$FrequencyTable[[byte]$byte])/$ByteArrayLength
            if ($byteProb -gt 0) {
                $fileEntropy += -$byteProb * [Math]::Log($byteProb, 2.0)
            }
        }
        $fileEntropy
        
    } else {
        "${FilePath} is locked or could not be found. Could not calculate entropy."
        Write-Error -Category InvalidArgument -Message ("{0} is locked or could not be found." -f $FilePath)
    }
}

if (Test-Path "$env:SystemRoot\Autorunsc.exe") {
    
    $fileRegex = New-Object System.Text.RegularExpressions.Regex "(([a-zA-Z]:|\\\\\w[ \w\.]*)(\\\w[- \w\.\\\{\}]*|\\%[ \w\.]+%+)+|%[ \w\.]+%(\\\w[ \w\.]*|\\%[ \w\.]+%+)*)"
    & $env:SystemRoot\Autorunsc.exe /accepteula -a * -c -h -s '*' -nobanner 2> $null | ConvertFrom-Csv | ForEach-Object {
        $_ | Add-Member NoteProperty ScriptMD5 $null
        $_ | Add-Member NoteProperty ScriptModTimeUTC $null
        $_ | Add-Member NoteProperty ShannonEntropy $null
        $_ | Add-Member NoteProperty ScriptLength $null

        if ($_."Image Path") {
            $_.ShannonEntropy = GetShannonEntropy $_."Image Path"
        }

        $fileMatches = $False
        if (($_."Image Path").ToLower() -match "\.bat|\.ps1|\.vbs") {
            $fileMatches = $fileRegex.Matches($_."Image Path")
        } elseif (($_."Launch String").ToLower() -match "\.bat|\.ps1|\.vbs") {
            $fileMatches = $fileRegex.Matches($_."Launch String")
        }

        if ($fileMatches) {
            for($i = 0; $i -lt $fileMatches.count; $i++) {
                $file = $fileMatches[$i].value
                if ($file -match "\.bat|\.ps1|\.vbs") {
                    if ($file -match "%userdnsdomain%") {
                        $scriptPath = "\\" + [System.Environment]::ExpandEnvironmentVariables($file)
                    } elseif ($file -match "%") {
                        $scriptPath = [System.Environment]::ExpandEnvironmentVariables($file)
                    } else {
                        $scriptPath = $file
                    }
                }
                $scriptPath = $scriptPath.Trim()
                $_.ScriptMD5,$_.ScriptModTimeUTC,$_.ScriptLength = Compute-FileHash $scriptPath
                $scriptPath = $null
            }
        }
        $_
    }
} else {
    Write-Error "Autorunsc.exe not found in $env:SystemRoot."
}

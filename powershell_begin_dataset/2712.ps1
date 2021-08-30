

Param(
    [Parameter(Mandatory=$False,Position=0)]
        [string]$BasePath="C:\inetpub\wwwroot",
    [Parameter(Mandatory=$False,Position=1)]
        [string]$extRegex="\..*$",
    [Parameter(Mandatory=$False,Position=2)]
        [long]$MinB=0,
    [Parameter(Mandatory=$False,Position=3)]
        [long]$MaxB=281474976645120
)

if (Test-Path $BasePath -PathType Container) {

        $files = (
            Get-ChildItem -Force -Path $BasePath -Recurse -ErrorAction SilentlyContinue |
            ? -FilterScript {
                ($_.Extension -match $extRegex) -and
                ($_.Length -ge $MinB -and $_.Length -le $MaxB)
            }
        )

        foreach ($childItem in $files) {
            $fileEntropy = 0.0
            $byteCounts = @{}
            $byteTotal = 0
            
            
            if(Test-Path $childItem.FullName -PathType Leaf) {
                $fileName = $childItem.FullName
                $fileBytes = [System.IO.File]::ReadAllBytes($fileName)

                foreach ($fileByte in $fileBytes) {
                    $byteCounts[$fileByte]++
                    $byteTotal++
                }

                foreach($byte in 0..255) {
                    $byteProb = ([double]$byteCounts[[byte]$byte])/$byteTotal
                    if ($byteProb -gt 0) {
                        $fileEntropy += (-1 * $byteProb) * [Math]::Log($byteProb, 2.0)
                    }
                }
            }
        
            $o = "" | Select-Object FullName, Length, CreationTimeUtc, LastAccessTimeUtc, LastWriteTimeUtc, Entropy
            $o.FullName = $childItem.FullName
            $o.Length   = $childItem.Length
            $o.CreationTimeUtc = $childItem.CreationTimeUtc
            $o.LastAccesstimeUtc = $childItem.LastAccessTimeUtc
            $o.LastWriteTimeUtc = $childItem.LastWriteTimeUtc
            $o.Entropy = $fileEntropy

            $o
        }
}
else {
    Write-Error -Message "Invalid path specified: $BasePath"
}

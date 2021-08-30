

Param(
    [Parameter(Mandatory=$False,Position=0)]
        [switch]$NoStacking=$False
)

function Get-Median {
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [double[]]$Data
    )

    $Data = $Data | Sort-Object
    if ($Data.Count%2) {
        
        $Median = $Data[[Math]::Floor($Data.Count/2)]
    }
    else {
        
        
        $Median = ($Data[$Data.Count/2], $Data[($Data.Count/2) - 1] | Measure-Object -Average).Average
    }
    return $Median
}

function Get-MedianAbsoluteDeviation {
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [double[]]$Data,
        [Parameter(Mandatory=$False,Position=1)]
            [double]$Center=(Get-Median $Data),
        [Parameter(Mandatory=$False,Position=2)]
            [double]$ScaleFactor=1.4826
    )

    
    
    
    
    
    

    $MAD = $ScaleFactor * (Get-Median ($Data | foreach { [Math]::Abs($_ - $Center) }))
    return $MAD
}

function Get-EntropyOutliers {
    Param(
        [Parameter(Mandatory=$True,Position=0)]
            [psobject]$lp_results
    )
    
    
    
    foreach ($lp_result in $lp_results) {
        $extension  = $lp_result.Extension
        $avgEntropy = $lp_result.AvgEntropy

        $lp_query = @"
            SELECT
                FullName,
                Length,
                Entropy
            FROM
                *WebRootListing.tsv
            WHERE
                EXTRACT_EXTENSION(FullName) = '$extension'
"@
        
        $lp_files = & logparser -stats:off -i:csv -o:csv -dtlines:0 -fixedsep:on "$lp_query" | ConvertFrom-Csv
        $ext_MAD  = Get-MedianAbsoluteDeviation ($lp_files).Entropy

        foreach ($lp_file in $lp_files) {
            if ([Math]::Abs($lp_file.Entropy - $avgEntropy) -gt (3 * $ext_MAD)) {
                $o = $lp_file | Select-Object "FullName","Length","Entropy"
                Add-Member -InputObject $o -MemberType NoteProperty -Name "EntropyAvg" -Value $avgEntropy
                $o
            }
        }
    }
}

if (Get-Command logparser.exe) {
    $lp_query = @"
        SELECT
            EXTRACT_EXTENSION(FullName) AS Extension,
            AVG(ALL TO_REAL(Entropy)) AS AvgEntropy
        FROM
            *WebRootListing.tsv
        GROUP BY
            EXTRACT_EXTENSION(FullName)
        HAVING
            AvgEntropy > 0.0
"@

    
    $lp_results = & logparser -stats:off -i:csv -o:csv -dtlines:0 -fixedsep:on "$lp_query" | ConvertFrom-Csv

    
    $outliers = Get-EntropyOutliers $lp_results

    if(!$NoStacking) {
        
        $lpquery = @"
            SELECT 
                COUNT(FullName,
                    Length,
                    Entropy,
                    EntropyAvg) as ct,
                FullName,
                Length,
                Entropy,
                EntropyAvg
            FROM STDIN
            GROUP BY
                FullName,
                Length,
                Entropy,
                EntropyAvg
            ORDER By
                ct ASC
"@

        $outliers = $outliers | ConvertTo-Csv -NoTypeInformation | 
            & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 "$lpquery"
    }

    $outliers
    
} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}


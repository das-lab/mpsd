



function Get-FolderSize {
    [cmdletbinding()]
    param (
        $Path = $PWD,
        [validateset('GCI', 'Robocopy', 'FSO', 'All')]
        $Use = 'Robocopy'
    )

    begin {
        

        function Resolve-FullPath ($Path = $PWD) {    
            if ( -not ([IO.Path]::IsPathRooted($Path)) ) {
                $Path = Join-Path (Get-Location) $Path
            }
            [IO.Path]::GetFullPath($Path)
        }

        function Get-FolderSizeFSO ($Path = $PWD) {
            begin {
                $fso = New-Object -ComObject scripting.filesystemobject
            }

            process {
                New-Object psobject -prop @{
                    Path = $Path
                    Count = $null
                    Size = $fso.GetFolder($Path).size
                }
            }

            end {
                [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($fso)
                [gc]::Collect()
            }
        }

        function Get-FolderSizeGCI ($Path = $PWD) {
            $items = Get-ChildItem $Path -Recurse -Force | ? {!$_.psiscontainer}

            New-Object psobject -prop @{
                Path = $Path
                Count = $items.count
                Size = ($items | Measure-Object -sum length).sum
            }
        }

        function Get-FolderSizeRobocopy ($Path = $PWD) {
            $lines = robocopy $Path NULL * /L /S /NJH /NFL /NDL /BYTES | ? {$_ -match '(?:Files|Bytes) :'}

            $hash = @{
                Path = $Path
                Count = $null
                Size = $null
            }
            $lines | % {
                switch -Regex ($_) {
                    'Files :\s+(\d+)' {$hash['Count'] = $Matches[1]}
                    'Bytes :\s+(\d+)' {$hash['Size'] = $Matches[1]}
                }
            }

            New-Object psobject -prop $hash
        }
    }

    process {
        $Path = Resolve-FullPath $Path

        
        $Path = $Path -replace '\\$'

        switch ($Use) {
            'All' {
                try {
                    $fso = Get-FolderSizeFSO $Path | select *, @{n='Use';e={'FSO'}}
                    if ($fso.size) {
                        $fso
                    } else {
                        1/0 
                    }
                } catch {
                    try {
                        $robo = Get-FolderSizeRobocopy $Path | select *, @{n='Use';e={'Robocopy'}}
                        if ($robo.size) {
                            $robo
                        } else {
                            1/0 
                        }
                    } catch {
                        try {
                            Get-FolderSizeGCI $Path | select *, @{n='Use';e={'GCI'}}
                        } catch {
                            New-Object psobject -prop @{
                                Path = $Path
                                Count = $null
                                Size = $null
                                Use = 'Error'
                            }
                        }
                    }
                }
            }
            'FSO' {Get-FolderSizeFSO $Path}
            'GCI' {Get-FolderSizeGCI $Path}
            'Robocopy' {Get-FolderSizeRobocopy $Path}
        }
    }
}

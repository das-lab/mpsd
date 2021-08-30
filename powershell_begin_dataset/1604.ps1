











function Get-Shortcut {
    param (
        [parameter(mandatory=$true)]
        [string]$Path
    )

    begin {
        $WshShell = New-Object -ComObject WScript.Shell
    }

    process {
        if (!$Path) {Throw 'No Source'}

        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut | select *
    }

    end {
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        $Shortcut, $WshShell | % {$null = Release-Ref $_}
    }
}

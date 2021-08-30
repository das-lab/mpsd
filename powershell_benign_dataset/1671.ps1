















function Create-Shortcut {
    param (
        [string]$Source,
        [string]$DestinationLnk,
        [string]$Arguments
    )

    begin {
        $WshShell = New-Object -ComObject WScript.Shell
    }

    process {
        if (!$Source) {Throw 'No Source'}
        if (!$DestinationLnk) {Throw 'No DestinationLnk'}

        $Shortcut = $WshShell.CreateShortcut($DestinationLnk)
        $Shortcut.TargetPath = $Source
        if ($Arguments) {
            $Shortcut.Arguments = $Arguments
        }
        $Shortcut.Save()
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

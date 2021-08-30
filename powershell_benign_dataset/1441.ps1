
function Compress-CItem
{
    
    [OutputType([IO.FileInfo])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]
        
        $Path,

        [string]
        
        $OutFile,

        [Switch]
        
        $UseShell,

        [Switch]
        
        $Force
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Ionic.Zip.dll' -Resolve)

        $zipFile = $null
        $fullPaths = New-Object -TypeName 'Collections.Generic.List[string]'

        if( $OutFile )
        {
            $OutFile = Resolve-CFullPath -Path $OutFile
            if( (Test-Path -Path $OutFile -PathType Leaf) )
            {
                if( -not $Force )
                {
                    Write-Error ('File ''{0}'' already exists. Use the `-Force` switch to overwrite.' -f $OutFile)
                    return
                }
            }
        }
        else
        {
            $OutFile = 'Carbon+Compress-CItem-{0}.zip' -f ([IO.Path]::GetRandomFileName())
            $OutFile = Join-Path -Path $env:TEMP -ChildPath $OutFile
        }

        if( $UseShell )
        {
            [byte[]]$data = New-Object byte[] 22
            $data[0] = 80
            $data[1] = 75
            $data[2] = 5
            $data[3] = 6
            [IO.File]::WriteAllBytes($OutFile, $data)

            $shellApp = New-Object -ComObject "Shell.Application"
            $copyHereFlags = (
                                
                                
                                
                                0x4 -bor 0x10 -bor 0x400        
                            )
            $zipFile = $shellApp.NameSpace($OutFile)
            $zipItemCount = 0
        }
        else
        {
            $zipFile = New-Object 'Ionic.Zip.ZipFile'
        }

    }

    process
    {
        if( -not $zipFile )
        {
            return
        }

        $Path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath' | ForEach-Object { $fullPaths.Add( $_ ) }
    }

    end
    {
        if( -not $zipFile )
        {
            return
        }

        $shouldProcessCaption = ('creating compressed file ''{0}''' -f $outFile)
        $maxPathLength = $fullPaths | Select-Object -ExpandProperty 'Length' | Measure-Object -Maximum
        $maxPathLength = $maxPathLength.Maximum
        $shouldProcessFormat = 'compressing {{0,-{0}}} to {{1}}@{{2}}' -f $maxPathLength
        
        $fullPaths | ForEach-Object { 
            $zipEntryName = Split-Path -Leaf -Path $_
            $operation = $shouldProcessFormat -f $_,$OutFile,$zipEntryName
            if( $PSCmdlet.ShouldProcess($operation,$operation,$shouldProcessCaption) )
            {
                if( $UseShell )
                {
                    [void]$zipFile.CopyHere($_, $copyHereFlags)
                    $entryCount = Get-ChildItem $_ -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
                    $zipItemCount += $entryCount
                }
                else
                {
                    if( Test-Path -Path $_ -PathType Container )
                    {
                        [void]$zipFile.AddDirectory( $_, $zipEntryName )
                    }
                    else
                    {
                        [void]$zipFile.AddFile( $_, '.' )
                    }
                }
            }
        }

        if( $UseShell )
        {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($zipFile)
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shellApp)
            do
            {
                try
                {
                    if( [Ionic.Zip.ZipFile]::CheckZip( $OutFile ) )
                    {
                        $zipFile = [Ionic.Zip.ZipFile]::Read($OutFile)
                        $count = $zipFile.Count
                        $zipFile.Dispose()
                        if( $zipItemCount -eq $count )
                        {
                            Write-Verbose ('Found {0} expected entries in ZIP file ''{1}''.' -f $zipItemCount,$OutFile)
                            break
                        }
                        Write-Verbose ('ZIP file ''{0}'' has {1} entries, but expected {2}. Looks like the Shell API is still writing to it.' -f $OutFile,$count,$zipItemCount)
                    }
                    else
                    {
                        Write-Verbose ('ZIP file ''{0}'' not valid. Looks like Shell API is still writing to it.' -f $OutFile)
                    }
                }
                catch
                {
                    Write-Verbose ('Encountered an exception checking if the COM Shell API has finished creating ZIP file ''{0}'': {1}' -f $OutFile,$_.Exception.Message) 
                    $Global:Error.RemoveAt(0)
                }
                Start-Sleep -Milliseconds 100
            }
            while( $true )
        }
        else
        {
            $operation = 'saving {0}' -f $OutFile
            if( $PSCmdlet.ShouldProcess( $operation, $operation, $shouldProcessCaption ) )
            {
                $zipFile.Save( $OutFile )
            }
            $zipFile.Dispose()
        }

        $operation = 'returning {0}' -f $OutFile
        if( $PSCmdlet.ShouldProcess($operation,$operation,$shouldProcessCaption) )
        {
            Get-Item -Path $OutFile
        }
    }
}

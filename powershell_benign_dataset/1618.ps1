

























































function Get-Files {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline=$true)]
        [string[]]$Path = $PWD,
        [string[]]$Include,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles,
        [switch]$Recurse,
        [switch]$FullName,
        [switch]$Directory,
        [switch]$File,
        [ValidateSet('Robocopy', 'Dir', 'EnumerateFiles', 'AlphaFS')]
        [string]$Method = 'Robocopy',
        [string]$AlphaFSdllPath = "$env:USERPROFILE\Dropbox\Documents\PSScripts\Modules\Shared\AlphaFS.dll"
    )
    
    begin {
        if ($Directory -and $File) {
            throw 'Cannot use both -Directory and -File at the same time.'
        }

        $Path = (Resolve-Path $Path).ProviderPath

        function CreateFolderObject {
            
            
            $name = ''
            
            $name += $(Split-Path $matches.FullName -Leaf)
            if (-not $name.ToString().EndsWith('\')) {
                
                $null += '\'
            }
            Write-Output $(new-object psobject -prop @{
                FullName = $matches.FullName
                DirectoryName = $($matches.FullName.substring(0, $matches.fullname.lastindexof('\')))
                Name = $name.ToString()
                Size = $null
                Extension = '[Directory]'
                DateModified = $null
            })
        }
    }

    process {
        if ($Method -eq 'Robocopy') {
            $params = '/L', '/NJH', '/BYTES', '/FP', '/NC', '/TS',  '/R:0', '/W:0'
            if ($Recurse) {$params += '/E'}
            if ($Include) {$params += $Include}
            if ($ExcludeDirs) {$params += '/XD', ('"' + ($ExcludeDirs -join '" "') + '"')}
            if ($ExcludeFiles) {$params += '/XF', ('"' + ($ExcludeFiles -join '" "') + '"')}
            foreach ($dir in $Path) {
                
                if ($dir.contains(' ')) {
                    $dir = '"' + $dir + ' "'
                }
            
            
                foreach ($line in $(robocopy $dir 'c:\tmep' $params)) {
                    
                    if (!$File -and $line -match '\s+\d+\s+(?<FullName>.*\\)$') {
                        if ($Include) {
                            if ($matches.FullName -like "*$($include.replace('*',''))*") {
                                if ($FullName) {
                                    Write-Output $( $matches.FullName )
                                } else {
                                    Write-Output $( CreateFolderObject )
                                }
                            }
                        } else {
                            if ($FullName) {
                                Write-Output $( $matches.FullName )
                            } else {
                                Write-Output $( CreateFolderObject )
                            }
                        }

                    
                    } elseif (!$Directory -and $line -match '(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*[^\\])$') {
                        if ($FullName) {
                            Write-Output $( $matches.FullName )
                        } else {
                            
                            $name = Split-Path $matches.FullName -Leaf
                            Write-Output $(new-object psobject -prop @{
                                FullName = $matches.FullName
                                DirectoryName = Split-Path $matches.FullName
                                Name = $name
                                Size = [int64]$matches.Size
                                Extension = $(if ($name.IndexOf('.') -ne -1) {'.' + $name.split('.')[-1]} else {'[None]'})
                                DateModified = $matches.Date
                            })
                        }
                    } else {
                        
                        
                    }
                }
            }
        } elseif ($Method -eq 'Dir') {
            $params = @('/a-d', '/-c') 
            if ($Recurse) { $params += '/S' }
            foreach ($dir in $Path) {
                foreach ($line in $(cmd /c dir $dir $params)) {
                    switch -Regex ($line) {
                        
                        'Directory of (?<Folder>.*)' {
                            $CurrentDir = $matches.Folder
                            if (-not $CurrentDir.EndsWith('\')) {
                                $CurrentDir = "$CurrentDir\"
                            }
                        }

                        
                        '(?<Date>.* [ap]m) +(?<Size>.*?) (?<Name>.*)' {
                            if ($FullName) {
                                Write-Output $( $CurrentDir + $matches.Name )
                            } else {
                                [System.IO.FileInfo]($CurrentDir + $matches.Name)
                                
                            }
                        }
                    }
                }
            }
        } elseif ($Method -eq 'AlphaFS') {
            ipmo $AlphaFSdllPath
            if ($Recurse) {
                $searchOption = 'AllDirectories'
            } else {
                $searchOption = 'TopDirectoryOnly'
            }
            foreach ($dir in $Path) {
                if ($FullName) {
                    Write-Output $( [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($dir, '*.*', $searchOption) )
                } else {
                    [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($dir, '*.*', $searchOption) | % {
                        Write-Output $( [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo($_) | select *, @{n='Extension';e={if ($_.filename.contains('.')) {$_.filename -replace '.*(\.\w+)$', '$1'}}} )
                    }
                }
            }
        } elseif ($Method -eq 'EnumerateFiles') {
            if ($Recurse) {
                $searchOption = 'AllDirectories'
            } else {
                $searchOption = 'TopDirectoryOnly'
            }
            foreach ($dir in $Path) {
                if ($FullName) {
                    Write-Output $( [System.IO.Directory]::EnumerateFiles($dir, '*.*', $searchOption) | % {$_} )
                } else {
                    [System.IO.Directory]::EnumerateFiles($dir, '*.*', $searchOption) | % {
                        Write-Output $([System.IO.FileInfo]$_)
                    }
                }
            }
        }
    }
}

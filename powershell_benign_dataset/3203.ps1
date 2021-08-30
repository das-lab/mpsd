function Get-FolderEntry { 
    
    [cmdletbinding(DefaultParameterSetName='Filter')]
    Param (
        [parameter(
            Position=0,
            ValueFromPipeline=$True,
            ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]$Path = $PWD,

        [parameter(ParameterSetName='Filter')]
        [string[]]$Filter = '*.*',    

        [parameter(ParameterSetName='Exclude')]
        [string[]]$ExcludeFolder
    )

    Begin {
        
        
            $array = @("/L","/S","/NJH","/BYTES","/FP","/NC","/NFL","/TS","/XJ","/R:0","/W:0")
            $regex = "^(?<Count>\d+)\s+(?<FullName>.*)"

        
            $params = New-Object System.Collections.Arraylist
            $params.AddRange($array)
    }

    Process {

        ForEach ($item in $Path) {
            Try {
                
                $item = (Resolve-Path -LiteralPath $item -ErrorAction Stop).ProviderPath
                
                If (-Not (Test-Path -LiteralPath $item -Type Container -ErrorAction Stop)) {
                    Write-Warning ("{0} is not a directory and will be skipped" -f $item)
                    Return
                }
                
                If ($PSBoundParameters['ExcludeFolder']) {
                    $filterString = ($ExcludeFolder | %{"'$_'"}) -join ','
                    $Script = "robocopy `"$item`" NULL $Filter $params /XD $filterString"
                }
                Else {
                    $Script = "robocopy `"$item`" NULL $Filter $params"
                }

                Write-Verbose ("Scanning {0}" -f $item)
                
                
                Invoke-Expression $Script | ForEach {
                    Try {
                        If ($_.Trim() -match $regex) {
                           $object = New-Object PSObject -Property @{
                                FullName = $matches.FullName
                                FileCount = [int64]$matches.Count
                                FullPathLength = [int] $matches.FullName.Length
                            } | select FullName, FileCount, FullPathLength
                            $object.pstypenames.insert(0,'System.IO.RobocopyDirectoryInfo')
                            Write-Output $object
                        } Else {
                            Write-Verbose ("Not matched: {0}" -f $_)
                        }
                    } Catch {
                        Write-Warning ("{0}" -f $_.Exception.Message)
                        Return
                    }
                }
            } Catch {
                Write-Warning ("{0}" -f $_.Exception.Message)
                Return
            }
        }
    }
}
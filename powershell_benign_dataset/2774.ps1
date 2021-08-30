

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$ModulePath="Modules\",
    [Parameter(Mandatory=$False,Position=1)]
        [String]$TargetList=$Null,
    [Parameter(Mandatory=$False,Position=2)]
        [String]$Target=$Null,
    [Parameter(Mandatory=$False,Position=3)]
        [int]$TargetCount=0,
    [Parameter(Mandatory=$False,Position=4)]
        [System.Management.Automation.PSCredential]$Credential=$Null,
    [Parameter(Mandatory=$False,Position=5)]
    [ValidateSet("CSV","JSON","TSV","XML","GL","SPLUNK")]
        [String]$OutputFormat="CSV",
    [Parameter(Mandatory=$False,Position=6)]
        [Switch]$Pushbin,
    [Parameter(Mandatory=$False,Position=7)]
        [Switch]$Rmbin,
    [Parameter(Mandatory=$False,Position=8)]
        [Int]$ThrottleLimit=0,
    [Parameter(Mandatory=$False,Position=9)]
    [ValidateSet("Ascii","BigEndianUnicode","Byte","Default","Oem","String","Unicode","Unknown","UTF32","UTF7","UTF8")]
        [String]$Encoding="Unicode",
    [Parameter(Mandatory=$False,Position=10)]
        [Switch]$UpdatePath,
    [Parameter(Mandatory=$False,Position=11)]
        [Switch]$ListModules,
    [Parameter(Mandatory=$False,Position=12)]
        [Switch]$ListAnalysis,
    [Parameter(Mandatory=$False,Position=13)]
        [Switch]$Analysis,
    [Parameter(Mandatory=$False,Position=14)]
        [Switch]$Transcribe,
    [Parameter(Mandatory=$False,Position=15)]
        [Switch]$Quiet=$False,
    [Parameter(Mandatory=$False,Position=16)]
        [Switch]$UseSSL,
    [Parameter(Mandatory=$False,Position=17)]
        [ValidateRange(0,65535)]
        [uint16]$Port=5985,
    [Parameter(Mandatory=$False,Position=18)]
        [ValidateSet("Basic","CredSSP","Default","Digest","Kerberos","Negotiate","NegotiateWithImplicitCredential")]
        [String]$Authentication="Kerberos",
    [Parameter(Mandatory=$false,Position=19)]
        [int32]$JSONDepth=20
)



Try {







Set-Variable -Name MAXPATH -Value 241 -Option Constant





if(!$Quiet) {
    $VerbosePreference = "Continue"
}

function FuncTemplate {

Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$ParamTemplate=$Null
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    
    if ($Error) {
        
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }

    Try { 
        
    } Catch [Exception] {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}


function Exit-Script {

    Set-Location $StartingPath
    if ($Transcribe) {
        [void] (Stop-Transcript)
    }

    if ($Error) {
        "Exit-Script function was passed an error, this may be a duplicate that wasn't previously cleared, or Kansa.ps1 has crashed." | Add-Content -Encoding $Encoding $ErrorLog
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }

    if (Test-Path($ErrorLog)) {
        Write-Output "Script completed with warnings or errors. See ${ErrorLog} for details."
    }

    if (!(Get-ChildItem -Force $OutputPath)) {
        
        "Output path was created, but Kansa finished with no hits, no runs and no errors. Nuking the folder."
        [void] (Remove-Item $OutputPath -Force)
    }

    Exit
}

function Get-Modules {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$ModulePath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    

    Write-Debug "`$ModulePath is ${ModulePath}."

    
    $ModuleScript = ($ModulePath -split " ")[0]
    $ModuleArgs   = @($ModulePath -split [regex]::escape($ModuleScript))[1].Trim()

    $Modules = $FoundModules = @()
    
    $ModuleHash = New-Object System.Collections.Specialized.OrderedDictionary

    if (!(ls $ModuleScript | Select-Object -ExpandProperty PSIsContainer)) {
        
        $ModuleHash.Add((ls $ModuleScript), $ModuleArgs)

        if (Test-Path($ModuleScript)) {
            $Module = ls $ModuleScript | Select-Object -ExpandProperty BaseName
            Write-Verbose "Running module: `n$Module $ModuleArgs"
            Return $ModuleHash
        }
    }
    $ModConf = $ModulePath + "\" + "Modules.conf"
    if (Test-Path($Modconf)) {
        Write-Verbose "Found ${ModulePath}\Modules.conf."
        
        Get-Content $ModulePath\Modules.conf | Foreach-Object { $_.Trim() } | ? { $_ -gt 0 -and (!($_.StartsWith("
            
            $ModuleScript = ($Module -split " ")[0]
            $ModuleArgs   = ($Module -split [regex]::escape($ModuleScript))[1].Trim()
            $Modpath = $ModulePath + "\" + $ModuleScript
            if (!(Test-Path($Modpath))) {
                "WARNING: Could not find module specified in ${ModulePath}\Modules.conf: $ModuleScript. Skipping." | Add-Content -Encoding $Encoding $ErrorLog
            } else {
                
                $ModuleHash.Add((ls $ModPath), $Moduleargs)
                
            }
        }
        
    } else {
        
        ls -r "${ModulePath}\Get-*.ps1" | Foreach-Object { $Module = $_
            $ModuleHash.Add($Module, $null)
        }
    }
    Write-Verbose "Running modules:`n$(($ModuleHash.Keys | Select-Object -ExpandProperty BaseName) -join "`n")"
    $ModuleHash
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Get-LoggingConf {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$OutputFormat,
    [Parameter(Mandatory=$False,Position=1)]
        [String]$LoggingConf = ".\logging.conf"
)

    Write-Debug "Results will be sent to $($OutputFormat)"
    $Error.Clear()
    

    if (Test-Path($LoggingConf)) {
        Write-Verbose "Found logging.conf"
        
        
        if ($OutputFormat -eq "splunk") {
            Get-Content $LoggingConf | Foreach-Object { $_.Trim() } | ? {$_.StartsWith('spl') -and (!($_.StartsWith("
        }
        elseif ($OutputFormat -eq "gl") {
            Get-Content $LoggingConf | Foreach-Object { $_.Trim() } | ? {$_.StartsWith('gl') -and (!($_.StartsWith("
        }
    }
}

function Load-AD {
    
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    if (Get-Module -ListAvailable | ? { $_.Name -match "ActiveDirectory" }) {
        $Error.Clear()
        Import-Module ActiveDirectory
        if ($Error) {
            "ERROR: Could not load the required Active Directory module. Please install the Remote Server Administration Tool for AD. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
            Exit
        }
    } else {
        "ERROR: Could not load the required Active Directory module. Please install the Remote Server Administration Tool for AD. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
        Exit
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Get-Forest {
    
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Forest = (Get-ADForest).Name

    if ($Forest) {
        Write-Verbose "Forest is ${forest}."
        $Forest
    } elseif ($Error) {
        
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        "ERROR: Get-Forest could not find current forest. Quitting." | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
        Exit
    }
}

function Get-Targets {
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$TargetList=$Null,
    [Parameter(Mandatory=$False,Position=1)]
        [int]$TargetCount=0
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Targets = $False
    if ($TargetList) {
        
        if ($TargetCount -eq 0) {
            $Targets = Get-Content $TargetList | Foreach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 }
        } else {
            $Targets = Get-Content $TargetList | Foreach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 } | Select-Object -First $TargetCount
        }
    } else {
        
        Write-Verbose "`$TargetCount is ${TargetCount}."
        if ($TargetCount -eq 0 -or $TargetCount -eq $Null) {
            $Targets = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name 
        } else {
            $Targets = Get-ADComputer -Filter * -ResultSetSize $TargetCount | Select-Object -ExpandProperty Name
        }
        
        
        
        
        
        foreach ($item in $Targets) {
            $numlines = $item | Measure-Object -Line
            if ($numlines.Lines -gt 1) {
                $lines = $item.Split("`n")
                $i = [array]::IndexOf($targets, $item)
                $targets[$i] = $lines[0]
            }
        }
        $TargetList = "hosts.txt"
        Set-Content -Path $TargetList -Value $Targets -Encoding $Encoding
    }

    if ($Targets) {
        Write-Verbose "`$Targets are ${Targets}."
        return $Targets
    } else {
        Write-Verbose "Get-Targets function found no targets. Checking for errors."
    }
    
    if ($Error) { 
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        "ERROR: Get-Targets function could not get a list of targets. Quitting."
        $Error.Clear()
        Exit
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"
}

function Get-LegalFileName {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Argument
)
    Write-Debug "Entering ($MyInvocation.MyCommand)"
    $Argument = $Arguments -join ""
    $Argument -replace [regex]::Escape("\") -replace [regex]::Escape("/") -replace [regex]::Escape(":") `
        -replace [regex]::Escape("*") -replace [regex]::Escape("?") -replace "`"" -replace [regex]::Escape("<") `
        -replace [regex]::Escape(">") -replace [regex]::Escape("|") -replace " "
}

function Get-Directives {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$Module,
    [Parameter(Mandatory=$False,Position=1)]
        [Switch]$AnalysisPath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    if ($AnalysisPath) {
        $Module = ".\Analysis\" + $Module
    }

    if (Test-Path($Module)) {
        
        $DirectiveHash = @{}

        Get-Content $Module | Select-String -CaseSensitive -Pattern "BINDEP|DATADIR" | Foreach-Object { $Directive = $_
            if ( $Directive -match "(^BINDEP|^
                $DirectiveHash.Add("BINDEP", $($matches[2]))
            }
            if ( $Directive -match "(^DATADIR|^
                $DirectiveHash.Add("DATADIR", $($matches[2])) 
            }
        }
        $DirectiveHash
    } else {
        "WARNING: Get-Directives was passed invalid module $Module." | Add-Content -Encoding $Encoding $ErrorLog
    }
}


function Get-TargetData {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [System.Collections.Specialized.OrderedDictionary]$Modules,
    [Parameter(Mandatory=$False,Position=2)]
        [System.Management.Automation.PSCredential]$Credential=$False,
    [Parameter(Mandatory=$False,Position=3)]
        [Int]$ThrottleLimit,
    [Parameter(Mandatory=$False,Position=4)]
        [Array]$LogConf
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    
    if ($Credential) {
        if ($UseSSL) {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -UseSSL -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -Credential $Credential
        } else {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -Credential $Credential
        }
    } else {
        if ($UseSSL) {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -UseSSL -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)
        } else {
            $PSSessions = New-PSSession -ComputerName $Targets -Port $Port -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)
        }
    }

    
    if ($Error) {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }

    $Modules.Keys | Foreach-Object { $Module = $_
        $ModuleName  = $Module | Select-Object -ExpandProperty BaseName
        $Arguments   = @()
        $Arguments   += $($Modules.Get_Item($Module)) -split ","
        if ($Arguments) {
            $ArgFileName = Get-LegalFileName $Arguments
        } else { $ArgFileName = "" }
            
        
        $DirectivesHash  = @{}
        $DirectivesHash = Get-Directives $Module
        if ($Pushbin) {
            $bindeps = [string]$DirectivesHash.Get_Item("BINDEP") -split ';'
            foreach($bindep in $bindeps) {
                if ($bindep) {
                
                    
                    
                    foreach ($PSSession in $PSSessions)
                    {
                        $RemoteWindir = Invoke-Command -Session $PSSession -ScriptBlock { Get-ChildItem -Force env: | Where-Object { $_.Name -match "windir" } | Select-Object -ExpandProperty value }
                        $null = Send-File -Path (ls $bindep).FullName -Destination $RemoteWindir -Session $PSSession
                    }
                }
            }
        }

        
        if ($LogConf) {
            $LogConf | foreach {
                $logAssign = $_ -split '=' 
                New-Variable -Name $logAssign[0] -Value $logAssign[1] -Force
            }
        } 
            
        
        if ($Arguments) {
            Write-Debug "Invoke-Command -Session $PSSessions -FilePath $Module -ArgumentList `"$Arguments`" -AsJob -ThrottleLimit $ThrottleLimit"
            $Job = Invoke-Command -Session $PSSessions -FilePath $Module -ArgumentList $Arguments -AsJob -ThrottleLimit $ThrottleLimit
            Write-Verbose "Waiting for $ModuleName $Arguments to complete."
        } else {
            Write-Debug "Invoke-Command -Session $PSSessions -FilePath $Module -AsJob -ThrottleLimit $ThrottleLimit"
            $Job = Invoke-Command -Session $PSSessions -FilePath $Module -AsJob -ThrottleLimit $ThrottleLimit                
            Write-Verbose "Waiting for $ModuleName to complete."
        }
        
        Wait-Job $Job
            
        
        $GetlessMod = $($ModuleName -replace "Get-") 
        
        
        
        $EstOutPathLength = $OutputPath.Length + ($GetlessMod.Length * 2) + ($ArgFileName.Length * 2)
        if ($EstOutPathLength -gt $MAXPATH) { 
            
            $PathDiff = [int] $EstOutPathLength - ($OutputPath.Length + ($GetlessMod.Length * 2) -gt 0)
            $MaxArgLength = $PathDiff - $MAXPATH
            if ($MaxArgLength -gt 0 -and $MaxArgLength -lt $ArgFileName.Length) {
                $OrigArgFileName = $ArgFileName
                $ArgFileName = $ArgFileName.Substring(0, $MaxArgLength)
                "WARNING: ${GetlessMod}'s output path contains the arguments that were passed to it. Those arguments were truncated from $OrigArgFileName to $ArgFileName to accomodate Window's MAXPATH limit of 260 characters." | Add-Content -Encoding $Encoding $ErrorLog
            }
        }
                            
        [void] (New-Item -Path $OutputPath -name ($GetlessMod + $ArgFileName) -ItemType Directory)
        $Job.ChildJobs | Foreach-Object { $ChildJob = $_
            $Recpt = Receive-Job $ChildJob
            
            
            if($Error) {
                $ModuleName + " reports error on " + $ChildJob.Location + ": `"" + $Error + "`"" | Add-Content -Encoding $Encoding $ErrorLog
                $Error.Clear()
            }

            
            
            $Outfile = $OutputPath + $GetlessMod + $ArgFileName + "\" + $ChildJob.Location + "-" + $GetlessMod + $ArgFileName
            if ($Outfile.length -gt 256) {
                "ERROR: ${GetlessMod}'s output path length exceeds 260 character limit. Can't write the output to disk for $($ChildJob.Location)." | Add-Content -Encoding $Encoding $ErrorLog
                Continue
            }

            
            switch -Wildcard ($OutputFormat) {
                "*csv" {
                    $Outfile = $Outfile + ".csv"
                    $Recpt | Export-Csv -NoTypeInformation -Encoding $Encoding $Outfile
                }
                "*json" {
                    $Outfile = $Outfile + ".json"
                    $Recpt | ConvertTo-Json -Depth $JSONDepth | Set-Content -Encoding $Encoding $Outfile
                }
                "*tsv" {
                    $Outfile = $Outfile + ".tsv"
                    
                    $Recpt | ConvertTo-Csv -NoTypeInformation -Delimiter "`t" | ForEach-Object { $_ -replace "`"" } | Set-Content -Encoding $Encoding $Outfile
                }
                "*xml" {
                    $Outfile = $Outfile + ".xml"
                    $Recpt | Export-Clixml $Outfile -Encoding $Encoding
                }
                "*gl" {
                    
                    
                    $Outfile = $Outfile + ".json"
                    $Recpt | ConvertTo-Json -Depth $JSONDepth | Set-Content -Encoding $Encoding $Outfile
                    
                    $glurl = "http://${glServerName}:$glServerPort/gelf"
                    
                    ForEach ($item in $Recpt){
                        $body = @{
                            message = $item
                            facility = "main"
                            host = $Target.Split(":")[0]
                            } | ConvertTo-Json
                            Invoke-RestMethod -Method Post -Uri $glurl -Body $body
                        }
                    
                } 
                "*splunk" {
                    
                    
                    $Outfile = $Outfile + ".json"
                    $Recpt | ConvertTo-Json -Depth $JSONDepth | Set-Content -Encoding $Encoding $Outfile
                    
                    $url = "http://${splServerName}:$splServerPort/services/collector/event"
                    $header = @{Authorization = "Splunk $splHECToken"}
                    
                    ForEach ($item in $Recpt){
                        $body = @{
                        event = $item
                        source = "$GetlessMod"
                        sourcetype = "_json"
                        host = $ChildJob.Location
                        } | ConvertTo-Json
                        Invoke-RestMethod -Method Post -Uri $url -Headers $header -Body $body
                        }
                    
                    } 
                
                default {
                    $Outfile = $Outfile + ".csv"
                    $Recpt | Export-Csv -NoTypeInformation -Encoding $Encoding $Outfile
                }
            }
        }

        
        
        Remove-Job $Job

        if ($rmbin) {
            if ($bindeps) {
                foreach ($bindep in $bindeps) {
                    $RemoteBinDep = "$RemoteWinDir\$(split-path -path $bindep -leaf)"
                    Invoke-Command -Session $PSSession -ScriptBlock { Remove-Item -force -path $using:RemoteBinDep}
                }
            }
        }

    }
    Remove-PSSession $PSSessions

    if ($Error) {
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}

function Push-Bindep {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$Module,
    [Parameter(Mandatory=$True,Position=2)]
        [String]$Bindep,
    [Parameter(Mandatory=$False,Position=3)]
        [System.Management.Automation.PSCredential]$Credential
        
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    Write-Verbose "${Module} has dependency on ${Bindep}."
    if (-not (Test-Path("$Bindep"))) {
        Write-Verbose "${Bindep} not found in ${ModulePath}bin, skipping."
        "WARNING: ${Bindep} not found in ${ModulePath}\bin, skipping." | Add-Content -Encoding $Encoding $ErrorLog
        Continue
    }
    Write-Verbose "Attempting to copy ${Bindep} to targets..."
    $Targets | Foreach-Object { $Target = $_
    Try {
        if ($Credential) {
            [void] (New-PSDrive -PSProvider FileSystem -Name "KansaDrive" -Root "\\$Target\ADMIN$" -Credential $Credential)
            Copy-Item "$Bindep" "KansaDrive:"
            [void] (Remove-PSDrive -Name "KansaDrive")
        } else {
            [void] (New-PSDrive -PSProvider FileSystem -Name "KansaDrive" -Root "\\$Target\ADMIN$")
            Copy-Item "$Bindep" "KansaDrive:"
            [void] (Remove-PSDrive -Name "KansaDrive")
        }
    } Catch [Exception] {
        "Caught: $_" | Add-Content -Encoding $Encoding $ErrorLog
    }
        if ($Error) {
            "WARNING: Failed to copy ${Bindep} to ${Target}." | Add-Content -Encoding $Encoding $ErrorLog
            $Error | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
        }
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}


function Send-File
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Path,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Destination,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.Runspaces.PSSession]$Session
	)
	process
	{
		foreach ($p in $Path)
		{
			try
			{
				if ($p.StartsWith('\\'))
				{
					Write-Verbose -Message "[$($p)] is a UNC path. Copying locally first"
					Copy-Item -Path $p -Destination ([environment]::GetEnvironmentVariable('TEMP', 'Machine'))
					$p = "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\$($p | Split-Path -Leaf)"
				}
				if (Test-Path -Path $p -PathType Container)
				{
					Write-Log -Source $MyInvocation.MyCommand -Message "[$($p)] is a folder. Sending all files"
					$files = Get-ChildItem -Force -Path $p -File -Recurse
					$sendFileParamColl = @()
					foreach ($file in $Files)
					{
						$sendParams = @{
							'Session' = $Session
							'Path' = $file.FullName
						}
						if ($file.DirectoryName -ne $p) 
						{
							$subdirpath = $file.DirectoryName.Replace("$p\", '')
							$sendParams.Destination = "$Destination\$subDirPath"
						}
						else
						{
							$sendParams.Destination = $Destination
						}
						$sendFileParamColl += $sendParams
					}
					foreach ($paramBlock in $sendFileParamColl)
					{
						Send-File @paramBlock
					}
				}
				else
				{
					Write-Verbose -Message "Starting WinRM copy of [$($p)] to [$($Destination)]"
					
					$sourceBytes = [System.IO.File]::ReadAllBytes($p);
					$streamChunks = @();
					
					
					$streamSize = 1MB;
					for ($position = 0; $position -lt $sourceBytes.Length; $position += $streamSize)
					{
						$remaining = $sourceBytes.Length - $position
						$remaining = [Math]::Min($remaining, $streamSize)
						
						$nextChunk = New-Object byte[] $remaining
						[Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
						$streamChunks +=, $nextChunk
					}
					$remoteScript = {
						if (-not (Test-Path -Path $using:Destination -PathType Container))
						{
							$null = New-Item -Path $using:Destination -Type Directory -Force
						}
						$fileDest = "$using:Destination\$($using:p | Split-Path -Leaf)"
						
						$destBytes = New-Object byte[] $using:length
						$position = 0
						
						
						foreach ($chunk in $input)
						{
							[GC]::Collect()
							[Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
							$position += $chunk.Length
						}
						
						[IO.File]::WriteAllBytes($fileDest, $destBytes)
						
						Get-Item -Force $fileDest
						[GC]::Collect()
					}
					
					
					$Length = $sourceBytes.Length
					$streamChunks | Invoke-Command -Session $Session -ScriptBlock $remoteScript
					Write-Verbose -Message "WinRM copy of [$($p)] to [$($Destination)] complete"
				}
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
	}
	
}


function Remove-Bindep {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$Targets,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$Module,
    [Parameter(Mandatory=$True,Position=2)]
        [String]$Bindep,
    [Parameter(Mandatory=$False,Position=3)]
        [System.Management.Automation.PSCredential]$Credential
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()
    $Bindep = $Bindep.Substring($Bindep.LastIndexOf("\") + 1)
    Write-Verbose "Attempting to remove ${Bindep} from remote hosts."
    $Targets | Foreach-Object { $Target = $_
        if ($Credential) {
            [void] (New-PSDrive -PSProvider FileSystem -Name "KansaDrive" -Root "\\$Target\ADMIN$" -Credential $Credential)
            Remove-Item "KansaDrive:\$Bindep" 
            [void] (Remove-PSDrive -Name "KansaDrive")
        } else {
            [void] (New-PSDrive -PSProvider FileSystem -Name "KansaDrive" -Root "\\$Target\ADMIN$")
            Remove-Item "KansaDrive:\$Bindep"
            [void] (Remove-PSDrive -Name "KansaDrive")
        }
        
        if ($Error) {
            "WARNING: Failed to remove ${Bindep} to ${Target}." | Add-Content -Encoding $Encoding $ErrorLog
            $Error | Add-Content -Encoding $Encoding $ErrorLog
            $Error.Clear()
        }
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}

function List-Modules {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$ModulePath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    ls $ModulePath | Foreach-Object { $dir = $_
        if ($dir.PSIsContainer -and ($dir.name -ne "bin" -or $dir.name -ne "Private")) {
            ls "${ModulePath}\${dir}\Get-*" | Foreach-Object { $file = $_
                $($dir.Name + "\" + (split-path -leaf $file))
            }
        } else {
            ls "${ModulePath}\Get-*" | Foreach-Object { $file = $_
                $file.Name
            }
        }
    }
    if ($Error) {
        
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}

function Set-KansaPath {
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    $kansapath  = Split-Path $Invocation.MyCommand.Path
    $Paths      = ($env:Path).Split(";")

    if (-not($Paths -match [regex]::Escape("$kansapath\Analysis"))) {
        
        $env:Path = $env:Path + ";$kansapath\Analysis"
    }

    $AnalysisPaths = (ls -Recurse "$kansapath\Analysis" | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName)
    $AnalysisPaths | ForEach-Object {
        if (-not($Paths -match [regex]::Escape($_))) {
            $env:Path = $env:Path + ";$_"
        }
    }
    if ($Error) {
        
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
}


function Get-Analysis {

Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$OutputPath,
    [Parameter(Mandatory=$True,Position=1)]
        [String]$StartingPath
)
    Write-Debug "Entering $($MyInvocation.MyCommand)"
    $Error.Clear()

    if (Get-Command -Name Logparser.exe) {
        $AnalysisScripts = @()
        $AnalysisScripts = Get-Content "$StartingPath\Analysis\Analysis.conf" | Foreach-Object { $_.Trim() } | ? { $_ -gt 0 -and (!($_.StartsWith("

        $AnalysisOutPath = $OutputPath + "\AnalysisReports\"
        [void] (New-Item -Path $AnalysisOutPath -ItemType Directory -Force)

        
        $DirectivesHash  = @{}
        $AnalysisScripts | Foreach-Object { $AnalysisScript = $_
            $DirectivesHash = Get-Directives $AnalysisScript -AnalysisPath
            $DataDir = $($DirectivesHash.Get_Item("DATADIR"))
            if ($DataDir) {
                if (Test-Path "$OutputPath$DataDir") {
                    Push-Location
                    Set-Location "$OutputPath$DataDir"
                    Write-Verbose "Running analysis script: ${AnalysisScript}"
                    $AnalysisFile = ((((($AnalysisScript -split "\\")[1]) -split "Get-")[1]) -split ".ps1")[0]
                    
                    & "$StartingPath\Analysis\${AnalysisScript}" | Set-Content -Encoding $Encoding ($AnalysisOutPath + $AnalysisFile + ".tsv")
                    Pop-Location
                } else {
                    "WARNING: Analysis: No data found for ${AnalysisScript}." | Add-Content -Encoding $Encoding $ErrorLog
                    Continue
                }
            } else {
                "WARNING: Analysis script, .\Analysis\${AnalysisScript}, missing 
                Continue
            }        
        }
    } else {
        "Kansa could not find logparser.exe in path. Skipping Analysis." | Add-Content -Encoding $Encoding -$ErrorLog
    }
    
    if ($Error) {
        
        $Error | Add-Content -Encoding $Encoding $ErrorLog
        $Error.Clear()
    }
    Write-Debug "Exiting $($MyInvocation.MyCommand)"    
} 





$Error.Clear()
$ErrorActionPreference = "SilentlyContinue"
$StartingPath = Get-Location | Select-Object -ExpandProperty Path




$Runtime = ([String] (Get-Date -Format yyyyMMddHHmmss))
$OutputPath = $StartingPath + "\Output_$Runtime\"
[void] (New-Item -Path $OutputPath -ItemType Directory -Force) 

If ($Transcribe) {
    $TransFile = $OutputPath + ([string] (Get-Date -Format yyyyMMddHHmmss)) + ".log"
    [void] (Start-Transcript -Path $TransFile)
}
Set-Variable -Name ErrorLog -Value ($OutputPath + "Error.Log") -Scope Script

if (Test-Path($ErrorLog)) {
    Remove-Item -Path $ErrorLog
}




if ($Encoding) {
    Set-Variable -Name Encoding -Value $Encoding -Scope Script
} else {
    Set-Variable -Name Encoding -Value "Unicode" -Scope Script
}




Write-Debug "Sanity checking parameters"
$Exit = $False
if ($TargetList -and -not (Test-Path($TargetList))) {
    "ERROR: User supplied TargetList, $TargetList, was not found." | Add-Content -Encoding $Encoding $ErrorLog
    $Exit = $True
}
if ($TargetCount -lt 0) {
    "ERROR: User supplied TargetCount, $TargetCount, was negative." | Add-Content -Encoding $Encoding $ErrorLog
    $Exit = $True
}

if ($Exit) {
    "ERROR: One or more errors were encountered with user supplied arguments. Exiting." | Add-Content -Encoding $Encoding $ErrorLog
    Exit
}
Write-Debug "Parameter sanity check complete."





Set-KansaPath
if ($UpdatePath) {
    
    
    Exit
}




Write-Debug "`$ModulePath is ${ModulePath}."
Write-Debug "`$OutputPath is ${OutputPath}."
Write-Debug "`$ServerList is ${TargetList}."



if ($ListModules) {
    
    
    List-Modules ".\Modules\"
    Exit
}



$Modules = Get-Modules -ModulePath $ModulePath



$LogConf = Get-LoggingConf -OutputFormat $OutputFormat



if ($ListAnalysis) {
    
    
    List-Modules ".\Analysis\"
    Exit
}



if ($TargetList) {
    $Targets = Get-Targets -TargetList $TargetList -TargetCount $TargetCount
} elseif ($Target) {
    $Targets = $Target
} else {
    Write-Verbose "No Targets specified. Building one requires RAST and will take some time."
    [void] (Load-AD)
    $Targets  = Get-Targets -TargetCount $TargetCount
}





if ($OutputFormat -eq "csv" -or $OutputFormat -eq "json" -or $OutputFormat -eq "tsv" -or $OutputFormat -eq "xml") {
    Get-TargetData -Targets $Targets -Modules $Modules -Credential $Credential -ThrottleLimit $ThrottleLimit
}

elseif ($OutputFormat -eq "gl" -or $OutputFormat -eq "splunk") {
    Get-TargetData -Targets $Targets -Modules $Modules -Credential $Credential -ThrottleLimit $ThrottleLimit -LogConf $LogConf
}



if ($Analysis) {
    Get-Analysis $OutputPath $StartingPath
}




if ($rmbin) {
    Remove-Bindep -Targets $Targets -Modules $Modules -Credential $Credential
}




Exit


} Catch {
    ("Caught: {0}" -f $_)
} Finally {
    Exit-Script
}

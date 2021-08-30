function Get-HostsFile {


    Param (
        [ValidateScript({Test-Path $_})]
        [String]
        $Path = (Join-Path $Env:SystemRoot 'System32\drivers\etc\hosts'),

        [Switch]
        $Show
    )

    $Hosts = Get-Content $Path -ErrorAction Stop

    $CommentLine = '^\s*
    $HostLine = '^\s*(?<IPAddress>\S+)\s+(?<Hostname>\S+)(\s*|\s+

    $TestIP = [Net.IPAddress] '127.0.0.1'
    $LineNum = 0

    for ($i = 0; $i -le $Hosts.Length; $i++) {
        if (!($Hosts[$i] -match $CommentLine) -and ($Hosts[$i] -match $HostLine)) {
            $IpAddress = $Matches['IPAddress']
            $Comment = ''

            if ($Matches['Comment']) {
                $Comment = $Matches['Comment']
            }

            $Result = New-Object PSObject -Property @{
                LineNumber = $LineNum
                IPAddress = $IpAddress
                IsValidIP = [Net.IPAddress]::TryParse($IPAddress, [Ref] $TestIP)
                Hostname = $Matches['Hostname']
                Comment = $Comment.Trim(' ')
            }

            $Result.PSObject.TypeNames.Insert(0, 'Hosts.Entry')

            Write-Output $Result
        }

        $LineNum++
    }

    if ($Show) {
        notepad $Path
    }
}

function New-HostsFileEntry {


    [CmdletBinding()] Param (
        [Parameter(Mandatory = $True, Position = 0)]
        [Net.IpAddress]
        $IPAddress,

        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname,

        [Parameter(Position = 2)]
        [ValidateNotNull()]
        [String]
        $Comment,

        [ValidateScript({Test-Path $_})]
        [String]
        $Path = (Join-Path $Env:SystemRoot 'System32\drivers\etc\hosts'),

        [Switch]
        $PassThru,

        [Switch]
        $Show
    )

    $HostsRaw = Get-Content $Path
    $Hosts = Get-HostsFile -Path $Path

    $HostEntry = "$IpAddress $Hostname"

    if ($Comment) {
        $HostEntry += " 
    }

    $HostEntryReplaced = $False

    for ($i = 0; $i -lt $Hosts.Length; $i++) {
        if ($Hosts[$i].Hostname -eq $Hostname) {
            if ($Hosts[$i].IpAddress -eq $IPAddress) {
                Write-Verbose "Hostname '$Hostname' and IP address '$IPAddress' already exist in $Path."
            } else {
                Write-Verbose "Replacing hostname '$Hostname' in $Path."
                $HostsRaw[$Hosts[$i].LineNumber] = $HostEntry
            }

            $HostEntryReplaced = $True
        }
    }

    if (!$HostEntryReplaced) {
        Write-Verbose "Appending hostname '$Hostname' and IP address '$IPAddress' to $Path."
        $HostsRaw += $HostEntry
    }

    $HostsRaw | Out-File -Encoding ascii -FilePath $Path -ErrorAction Stop

    if ($PassThru) { Get-HostsFile -Path $Path }

    if ($Show) {
        notepad $Path
    }
}

function Remove-HostsFileEntry {


    Param (
        [Parameter(Mandatory = $True, ParameterSetName = 'IPAddress')]
        [Net.IpAddress]
        $IPAddress,

        [Parameter(Mandatory = $True, ParameterSetName = 'Hostname')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname,

        [ValidateScript({ Test-Path $_ })]
        [String]
        $Path = (Join-Path $Env:SystemRoot 'System32\drivers\etc\hosts'),

        [Switch]
        $PassThru,

        [Switch]
        $Show,

        [Parameter(ParameterSetName = 'PSObjectArray', ValueFromPipeline = $True)]
        [PSObject[]]
        $HostsEntry
    )

    BEGIN {
        $HostsRaw = Get-Content $Path

        if ($IPAddress -or $Hostname) {
            $HostsEntry = Get-HostsFile -Path $Path
        }

        $ExcludedLineNumbers = @()

        $StringBuilder = New-Object Text.StringBuilder
    }

    PROCESS {
        foreach ($Entry in $HostsEntry) {
            if ($Entry.PSObject.TypeNames[0] -eq 'Hosts.Entry') {
                if ($IPAddress) {
                    if ($Entry.IPAddress -eq $IPAddress) {
                        Write-Verbose "Removing line 
                        $ExcludedLineNumbers += $Entry.LineNumber
                    }
                } elseif ($Hostname) {
                    if ($Entry.Hostname -eq $Hostname) {
                        Write-Verbose "Removing line 
                        $ExcludedLineNumbers += $Entry.LineNumber
                    }
                } else {
                    Write-Verbose "Removing line 
                    $ExcludedLineNumbers += $Entry.LineNumber
                }
            }
        }
    }

    END {
        for ($i = 0; $i -lt $HostsRaw.Length; $i++) {
            if (!$ExcludedLineNumbers.Contains($i)) {
                $null = $StringBuilder.AppendLine($HostsRaw[$i])
            }
        }

        $StringBuilder.ToString() | Out-File $Path

        if ($PassThru) { Get-HostsFile -Path $Path }

        if ($Show) {
            notepad $Path
        }
    }
}
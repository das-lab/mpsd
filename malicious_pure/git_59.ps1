function Find-AVSignature
{


    [CmdletBinding()] Param(
        [Parameter(Mandatory = $True)]
        [ValidateRange(0,4294967295)]
		[UInt32]
        $StartByte,

        [Parameter(Mandatory = $True)]
        [String]
        $EndByte,

        [Parameter(Mandatory = $True)]
        [ValidateRange(0,4294967295)]
		[UInt32]
        $Interval,

        [String]
		[ValidateScript({Test-Path $_ })]
        $Path = ($pwd.path),

        [String]
        $OutPath = ($pwd),
		
		
		[ValidateRange(1,2097152)]
		[UInt32]
		$BufferLen = 65536,
		
        [Switch] $Force
		
    )

    
    if (!(Test-Path $Path)) {Throw "File path not found"}
    $Response = $True
    if (!(Test-Path $OutPath)) {
        if ($Force -or ($Response = $psCmdlet.ShouldContinue("The `"$OutPath`" does not exist! Do you want to create the directory?",""))){new-item ($OutPath)-type directory}
	}
    if (!$Response) {Throw "Output path not found"}
    if (!(Get-ChildItem $Path).Exists) {Throw "File not found"}
    [Int32] $FileSize = (Get-ChildItem $Path).Length
    if ($StartByte -gt ($FileSize - 1) -or $StartByte -lt 0) {Throw "StartByte range must be between 0 and $Filesize"}
    [Int32] $MaximumByte = (($FileSize) - 1)
    if ($EndByte -ceq "max") {$EndByte = $MaximumByte}
	
	
	[Int32]$EndByte = $EndByte 
	
	
    if ($EndByte -gt $FileSize) {$EndByte = $MaximumByte}
	
	
	if ($EndByte -lt $StartByte) {$EndByte = $StartByte + $Interval}

	Write-Verbose "StartByte: $StartByte"
	Write-Verbose "EndByte: $EndByte"
	
    
    [String] $FileName = (Split-Path $Path -leaf).Split('.')[0]

    
    [Int32] $ResultNumber = [Math]::Floor(($EndByte - $StartByte) / $Interval)
    if (((($EndByte - $StartByte) % $Interval)) -gt 0) {$ResultNumber = ($ResultNumber + 1)}
    
    
    $Response = $True
    if ( $Force -or ( $Response = $psCmdlet.ShouldContinue("This script will result in $ResultNumber binaries being written to `"$OutPath`"!",
             "Do you want to continue?"))){}
    if (!$Response) {Return}
    
    Write-Verbose "This script will now write $ResultNumber binaries to `"$OutPath`"." 
    [Int32] $Number = [Math]::Floor($Endbyte/$Interval)
    
		
		
		[Byte[]] $ReadBuffer=New-Object byte[] $BufferLen
		[System.IO.FileStream] $ReadStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read, $BufferLen)
		
        
        [Int32] $i = 0
        for ($i -eq 0; $i -lt $ResultNumber + 1 ; $i++)
        {
			
			if ($i -eq $ResultNumber) {[Int32]$SplitByte = $EndByte}
			else {[Int32] $SplitByte = (($StartByte) + (($Interval) * ($i)))}
			
			Write-Verbose "Byte 0 -> $($SplitByte)"
			
			
			$ReadStream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
			
			
			[String] $outfile = Join-Path $OutPath "$($FileName)_$($SplitByte).bin"
			[System.IO.FileStream] $WriteStream = New-Object System.IO.FileStream($outfile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, $BufferLen)
			
			[Int32] $BytesLeft = $SplitByte
			Write-Verbose "$($WriteStream.name)"
			
			
			while ($BytesLeft -gt $BufferLen){
				[Int32]$count = $ReadStream.Read($ReadBuffer, 0, $BufferLen)
				$WriteStream.Write($ReadBuffer, 0, $count)
				$BytesLeft = $BytesLeft - $count
			}
			
			
			do {
				[Int32]$count = $ReadStream.Read($ReadBuffer, 0, $BytesLeft)
				$WriteStream.Write($ReadBuffer, 0, $count)
				$BytesLeft = $BytesLeft - $count			
			}
			until ($BytesLeft -eq 0)
			$WriteStream.Close()
			$WriteStream.Dispose()
        }
        Write-Verbose "Files written to disk. Flushing memory."
        $ReadStream.Dispose()
        
		
        [System.GC]::Collect()
        Write-Verbose "Completed!"
}

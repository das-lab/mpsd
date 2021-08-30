

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true,Position=0,ParameterSetName="SinglePartition")]
	[Parameter(Mandatory=$false,Position=0,ParameterSetName="Default")]
		[ValidateScript({ 
			$filter = [String]::Format("DeviceId like '%PHYSICALDRIVE{0}'", $_.ToString())
			if ($null -ne (Get-WMIObject -Class Win32_DiskDrive -Filter $filter)) {
				$true
			}
			else {
				$msg = [String]::Format("No physical drive of index {0} on this host.", $_.ToString())
				throw $msg
			}
		})]
		[int]$Disk,
	[Parameter(Mandatory=$true,Position=1,ParameterSetName="SinglePartition")]
		[ValidateScript({ 
			
			
			[string]$myDisk = (Get-Variable -Name Disk -Scope 1).Value
			$filter = [String]::Format("DeviceId like '%PHYSICALDRIVE{0}'", $myDisk)
			if (($_ -lt (Get-WMIObject -Class Win32_DiskDrive -Filter $filter).Partitions) -and ($_ -ge 0)) {
				$true
			}
			else {
				$msg = [String]::Format("Partition index {0} is outside the valid partition range.", $_.ToString())
				throw $msg
			}
		})]
		[int]$Partition
)

BEGIN {

	function Open-RawStream {
		[CmdletBinding()]
		Param(
			[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
			[string]$Path
		)

		$orig_EA = $ErrorActionPreference
		$ErrorActionPreference = "SilentlyContinue"
		Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern SafeFileHandle CreateFileW(
	  [MarshalAs(UnmanagedType.LPWStr)] string filename,
	  [MarshalAs(UnmanagedType.U4)] FileAccess access,
	  [MarshalAs(UnmanagedType.U4)] FileShare share,
	  IntPtr securityAttributes,
	  [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
	  [MarshalAs(UnmanagedType.U4)] FileAttributes flagsAndAttributes,
	  IntPtr templateFile);

public static FileStream OpenFileStream(string path) {
	SafeFileHandle handle = CreateFileW(path, 
										FileAccess.Read, 
										FileShare.ReadWrite, 
										IntPtr.Zero, 
										FileMode.Open, 
										FileAttributes.Normal, 
										IntPtr.Zero);

	if (handle.IsInvalid) {
		Marshal.ThrowExceptionForHR(Marshal.GetHRForLastWin32Error());
	}

	return new FileStream(handle, FileAccess.Read);
}
"@ -Name Win32 -Namespace System -UsingNamespace System.IO,Microsoft.Win32.SafeHandles
		$ErrorActionPreference = $orig_EA

		try {
			$fs = [System.Win32]::OpenFileStream($path)
			return $fs
		}
		catch {
			throw $Error[0]
		}
	}
	
	function Read-FromRawStream {
		
		Param (
			[Parameter(Mandatory=$true, Position=0)]
				$Stream,
			[Parameter(Mandatory=$true, Position=1)]
			[ValidateScript(
				{ 
					if( $_ -ge 0 ) { $true }
					else { throw "Length parameter cannot be negative."}
				}
			)]
				[uint64]$Length,
			[Parameter(Mandatory=$false, Position=2)]
			[ValidateScript(
				{ 
					if( $_ -ge 0 ) { $true }
					else { throw "Offset parameter cannot be negative."}
				}
			)]
				[int64]$Offset = 0
		)

		
		
		if ($MyInvocation.BoundParameters.ContainsKey("Offset")) {
			$suppress = $Stream.Seek($Offset, [System.IO.SeekOrigin]::Begin)
		}
		
		
		[byte[]]$buffer = New-Object byte[] $Length
		$suppress = $Stream.Read($buffer, 0, $Length)

		return $buffer
	}
	
	function Format-AsHex {
		
		Param (
			 [Parameter(Mandatory=$true, Position=0)]
				[byte[]]$Bytes,
			 [Parameter(Mandatory=$false, Position=1)] 
				[switch]$NoOffset,
			 [Parameter(Mandatory=$false, Position=2)] 
				[switch]$NoText
		)

		$placeholder = "." 
		
		
        $counter = 0
        $header = "            0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F"
        $nextLine = "{0}   " -f  [Convert]::ToString($counter, 16).ToUpper().PadLeft(8, '0')
        $asciiEnd = ""

        
        "`r`n$header`r`n"

		foreach ($byte in $bytes) {
			$nextLine += "{0:X2} " -f $byte

			if ([Char]::IsLetterOrDigit($byte) -or [Char]::IsPunctuation($byte) -or [Char]::IsSymbol($byte) ) { 
				$asciiEnd += [Char] $byte 
			}
			else {
				$asciiEnd += $placeholder 
			}

			$counter += 1

			
            
            if(($counter % 16) -eq 0) {
                "$nextLine $asciiEnd"
                $nextLine = "{0}   " -f [Convert]::ToString($counter, 16).ToUpper().PadLeft(8, '0')
                $asciiEnd = ""
            }
		}

		
        
        
        if(($counter % 16) -ne 0) {
            while(($counter % 16) -ne 0) {
                $nextLine += "   "
                $asciiEnd += " "
                $counter++;
            }
            "$nextLine $asciiEnd"
        }

        ""
	}
	
	function Get-PartitionStats {
        Param(
            [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
                [byte[]]$PartitionEntry,
            [Parameter(Mandatory=$false, Position=1)]
                [int]$SectorSize = 0x200
        )

        

        BEGIN {  
            $PartitionTypes = @{
                "00" = "Empty";
                "05" = "Microsoft Extended";
                "07" = "NTFS";
                "82" = "Linux swap";
                "83" = "Linux";
                "84" = "Hibernation";
                "85" = "Linux Extended";
                "86" = "NTFS Volume Set";
                "87" = "NTFS Volume Set";
                "EE" = "EFI GPT Disk";
                "EF" = "EFI System Partition"
            }
        }
        PROCESS {
            $o = "" | Select-Object Bootable, Type, FirstSector, Length
            
            
            if ($PartitionEntry[0] -eq [byte]0x80) {
                $o.Bootable = $true
            }
            else {
                $o.Bootable = $false
            }

            
            $PartitionTypeString = "{0:X2}" -f $PartitionEntry[4]
            if ($PartitionTypes.ContainsKey($PartitionTypeString)) {
                $o.Type = $PartitionTypes[$PartitionTypeString]
            }
            else {
                $o.Type = "0x{0}", $PartitionTypeString
            }

            
            $FirstSector = $PartitionEntry[8..11]
            [Array]::Reverse($FirstSector) 
            $FirstSector | % { $o.FirstSector += ("{0:X2}" -f $_)}
            $o.FirstSector = "0x" + $($o.FirstSector).TrimStart("0")

            
            $LengthArr = $PartitionEntry[12..15]
            $Length = [BitConverter]::ToUInt32($PartitionEntry, 12) * $SectorSize
            [Array]::Reverse($LengthArr) 
            $LengthStr = ""
            $LengthArr | % { $LengthStr += ("{0:X2}" -f $_)}
			$LengthStrHr = ConvertTo-ReadableSize $Length
            $o.Length = "0x{0} sectors ({1:F0} {2})" -f $LengthStr.TrimStart("0"), $LengthStrHr.Value, $LengthStrHr.Label

            $o
        }
        END {  }
    }

	function Parse-StdInfoEntry {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$AttributeContent,
			[Parameter(Mandatory=$false, Position=1)]
				[bool]$IsResident = $true
		)

		if ($IsResident) {
			$o = "" | Select-Object SI_Created, SI_Modified, SI_EntryModified, SI_Accessed, SI_UpdateSequenceNumber
			$o.SI_Created = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x00))
			$o.SI_Modified = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x08))
			$o.SI_EntryModified = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x10))
			$o.SI_Accessed = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x18))

		
			if ($AttributeContent.Length -ge 0x48) {
				$o.SI_UpdateSequenceNumber = [BitConverter]::ToUInt64($AttributeContent, 0x40)
				
			}
			else {
				$o.SI_UpdateSequenceNumber = 0
			}

			$o
		}
		else {
			$false
		}
	}

	function Parse-FilenameEntry {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$AttributeContent,
			[Parameter(Mandatory=$false, Position=1)]
				[bool]$IsResident = $true
		)

		if ($IsResident) {
			$o = "" | Select-Object FN_Created, FN_Modified, FN_EntryModified, FN_Accessed, FN_ParentEntry, `
									FN_ParentSeq, FN_AllocatedSize, FN_RealSize, FN_NameSpace, FN_Name

			
			$o.FN_ParentEntry = ([BitConverter]::ToUInt16($AttributeContent, 0x04) -shl 16) + ([BitConverter]::ToUInt32($AttributeContent, 0x00))
			$o.FN_ParentSeq = [BitConverter]::ToUInt16($AttributeContent, 0x06)
			$o.FN_Created = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x08))
			$o.FN_Modified = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x10))
			$o.FN_EntryModified = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x18))
			$o.FN_Accessed = [DateTime]::FromFileTimeUtc([BitConverter]::ToUInt64($AttributeContent, 0x20))
			$o.FN_AllocatedSize = [BitConverter]::ToUInt64($AttributeContent, 0x28)
			$o.FN_RealSize = [BitConverter]::ToUint64($AttributeContent, 0x30)
			$o.FN_NameSpace = switch ([int]$AttributeContent[0x41]) {
				0 { "POSIX" }
				1 { "Win32" }
				2 { "DOS" }
				3 { "Win32 & DOS" }
				default { "Unknown" }
			}

			
			
			[int]$FN_NameEnd = 0x42 + ($AttributeContent[0x40] * 2) - 1
			$o.FN_Name = [Text.UnicodeEncoding]::Unicode.GetString($AttributeContent[0x42..$FN_NameEnd])

			$o
		}
		else {
			$false
		}
	}

	function Parse-DataEntry {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$AttributeContent,
			[Parameter(Mandatory=$false, Position=1)]
				[bool]$IsResident = $false
		)

		$o = "" | Select-Object DATA_Resident, DATA_SizeAllocated, DATA_SizeActual, DATA_Runlist, `
								DATA_StreamName, DATA_ResidentData

		
		
		$o.DATA_Resident = $IsResident
		$o.DATA_StreamName = (Get-Variable -Name AttributeName -Scope 1).Value

		if ($IsResident) {
			$o.DATA_ResidentData = Format-AsHex $AttributeContent
		}
		else {
			$o.DATA_SizeAllocated = (Get-Variable -Name AttributeSizeAllocated -Scope 1).Value
			$o.DATA_SizeActual = (Get-Variable -Name AttributeSizeActual -Scope 1).Value
			$o.DATA_Runlist = Parse-RunList $AttributeContent
		}

		$o
	}

	function Parse-RunList {
		
	    Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$RunList
		)
		$index = 0
		$Previous_RunStart = 0
		
		$out = @()
	
		$NextEntryStart = 0
		while (($NextEntryStart -lt $RunList.Length) -and ($RunList[$NextEntryStart] -ne 0x00)) {
			
	        $o = New-Object psobject
			[int]$RunLengthBytes = $RunList[$NextEntryStart] -band 0x0F
			[int]$RunOffsetBytes = $RunList[$NextEntryStart] -shr 4
	
			[byte[]]$RunLenPart = 
				if ($RunLengthBytes -gt 0) {
					$RLenStart = $NextEntryStart + 1
					$RLenEnd   = $RLenStart + $RunLengthBytes - 1
					$RunList[$RLenStart..$RLenEnd]
				}
				else {
					$RLenEnd = $NextEntryStart
					0x00
				}
			
			[byte[]]$RunOffPart = 
	            if ($RunOffsetBytes -gt 0) {
	                $ROffStart = $RLenEnd + 1
	        		$ROffEnd = $ROffStart + $RunOffsetBytes - 1
	                $RunList[$ROffStart..$ROffEnd]
	            }
	            else {
	                $ROffEnd = $RLenEnd
	                0x00
	            }
	
			
			
			while ($RunLenPart.Length -lt 8) {
				$RunLenPart += 0x00
			}
	
			
			if (($RunOffPart[($RunOffPart.Length - 1)] -band 0x80) -eq 0) {
				
				while ($RunOffPart.Length -lt 8) {
					$RunOffPart += 0x00
				}
			}
			else {
				
				while ($RunOffPart.Length -lt 8) {
					$RunOffPart += 0xFF
				}
			}
	
			$RunLength = [BitConverter]::ToUInt64($RunLenPart, 0)
			$RunOffset = [BitConverter]::ToInt64($RunOffPart, 0)
	        $RunOffset = 
	            if($RunOffset -ne 0) {
	                $Previous_RunStart += $RunOffset
	                $Previous_RunStart
	            } 
	            else {
	                0x00
	                $Prevous_RunStart = $Previous_RunStart
	            }
	
			$o | Add-Member -MemberType NoteProperty -Name Run_Index -Value $index
			$o | Add-Member -MemberType NoteProperty -Name Run_Length -Value $RunLength
			$o | Add-Member -MemberType NoteProperty -Name Run_Start -Value $RunOffset
	
			$NextEntryStart = $ROffEnd + 1
			$index += 1
			
			$out += $o
		}
	
	    return ,$out
	}

	function Parse-AttributeListEntry {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$AttributeContent,
			[Parameter(Mandatory=$false, Position=1)]
				[bool]$IsResident = $true
		)
	
		$out = @()
		$NextAttributeStart = 0
	
		while ($NextAttributeStart -lt $AttributeContent.Length) {
			$o = New-Object psobject
			$o | Add-Member -MemberType NoteProperty -Name AttributeTypeCode -Value ([BitConverter]::ToUInt32($AttributeContent, $NextAttributeStart))
			$o | Add-Member -MemberType NoteProperty -Name AttributeTypeName -Value ""
	        $o | Add-Member -MemberType NoteProperty -Name AttributeId -Value ($AttributeContent[($NextAttributeStart + 0x18)])
			$o | Add-Member -MemberType NoteProperty -Name StartingVcn -Value ([BitConverter]::ToUInt64($AttributeContent, $NextAttributeStart + 0x08))
			$o | Add-Member -MemberType NoteProperty -Name AttributeFileReferenceNumber -Value (([BitConverter]::ToUInt16($AttributeContent, $NextAttributeStart + 0x14) -shl 16) + ([BitConverter]::ToUInt32($AttributeContent, $NextAttributeStart + 0x10)))
			$o | Add-Member -MemberType NoteProperty -Name AttributeFRNSequenceNumber -Value ([BitConverter]::ToUInt16($AttributeContent, 0x16))
			$o | Add-Member -MemberType NoteProperty -Name AttributeName -Value ""
						
			[int]$NameLength = $AttributeContent[($NextAttributeStart + 0x06)]
			[int]$NameOffset = $AttributeContent[($NextAttributeStart + 0x07)]
	
			if ($NameLength -gt 0) {
				$o.AttributeName = [System.Text.UnicodeEncoding]::Unicode.GetString($AttributeContent[$NameOffset..($NameOffset + $NameLength)])
			}
	
	        $o.AttributeTypeName = 
	            switch ($o.AttributeTypeCode) {
			        0x10 { "STANDARD_INFORMATION" }
			        0X20 { "ATTRIBUTE_LIST" }
			        0X30 { "FILE_NAME" }
			        0X40 { "OBJECT_ID" }
			        0X60 { "VOLUME_NAME" }
			        0X70 { "VOLUME_INFORMATION" }
			        0X80 { "DATA" }
			        0X90 { "INDEX_ROOT" }
			        0XA0 { "INDEX_ALLOCATION" }
			        0XB0 { "BITMAP" }
			        0XCO { "REPARSE_POINT" }
			        DEFAULT { "Undefined" }
				}
	
			$EntryLength = [BitConverter]::ToUInt16($AttributeContent, $NextAttributeStart + 0x04)
			$NextAttributeStart += $EntryLength
			$out += $o
		}
		
		return ,$out	
	}

	function Parse-ObjectIdEntry {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$AttributeContent,
			[Parameter(Mandatory=$false, Position=1)]
				[bool]$IsResident = $true
		)
	
		function Get-Guid {
	        Param(
	            [byte[]]$guid
	        )
	
	        $newGuid = New-Object Guid (,$guid)
	        $newGuid.ToString()
	    }
	
	    $o = New-Object psobject
		switch ($AttributeContent.Length) {
			{$_ -ge 16} { $o | Add-Member -MemberType NoteProperty -Name ObjectId -Value (Get-Guid $AttributeContent[0x00..0x0F])}
			{$_ -ge 32} { $o | Add-Member -MemberType NoteProperty -Name BirthVolumeId -Value (Get-Guid $AttributeContent[0x10..0x1F])}
			{$_ -ge 48} { $o | Add-Member -MemberType NoteProperty -Name BirthObjectId -Value (Get-Guid $AttributeContent[0x20..0x2F])}
			{$_ -eq 64} { $o | Add-Member -MemberType NoteProperty -Name BirthDomainId -Value (Get-Guid $AttributeContent[0x30..0x3F])}
			default { return $false }
		}
	
		$o
	}
    
	function Parse-MftRecord {
		
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				[byte[]]$MftRecord,
			[Parameter(Mandatory=$false, Position=1)]
				[int]$SectorSize = 0x200
		)

		
		[byte[]]$FILE_SIG = 0x46, 0x49, 0x4C, 0x45
		[byte[]]$INDX_SIG = 0x49, 0x4E, 0x44, 0x58
		[byte[]]$EOF_SIG  = 0xFF, 0xFF, 0xFF, 0xFF
		[byte[]]$NULL_BYTE = 0x00
		
		
		$ParsedMftRecord = New-Object psobject

		
		
		if ($null -eq (Compare-Object $MftRecord[0x00..0x03] $FILE_SIG)) {
			
			$FixupOffset = [BitConverter]::ToUInt16($MftRecord, 0x4)
			$FixupEntries = [BitConverter]::ToUInt16($MftRecord, 0x06)
			$LogSequenceNumber = [BitConverter]::ToUInt64($MftRecord, 0x08)
			$SequenceValue = [BitConverter]::ToUInt16($MftRecord, 0x10)
			$LinkCount = [BitConverter]::ToUInt16($MftRecord, 0x12)
			$NextAttributeOffset = [BitConverter]::ToUInt16($MftRecord, 0x14)
			$Flags = [BitConverter]::ToUint16($MftRecord, 0x16)
			$EntrySizeUsed = [BitConverter]::ToUInt32($MftRecord, 0x18)
			$EntrySizeAllocated = [BitConverter]::ToUInt32($MftRecord, 0x1C)
			$BaseRecordReference = $MftRecord[0x20..27] 
			$NextAttributeId = [BitConverter]::ToUInt16($MftRecord, 0x28)

			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name LogSequenceNumber -Value $LogSequenceNumber
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name SequenceValue -Value $SequenceValue
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name LinkCount -Value $LinkCount
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name Flags -Value $Flags
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name EntrySizeUsed -Value $EntrySizeUsed
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name EntrySizeAllocated -Value $EntrySizeAllocated
			$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name BaseRecordReference -Value $BaseRecordReference

			
			if ($FixupEntries -gt 0) {
				$FixupSignature = $MftRecord[$FixupOffset..($FixupOffset + 1)]
				for ($i = 1; $i -lt $FixupEntries; $i++) {
					$SourceOffset = $FixupOffset + (2 * $i)
					$TargetOffset = ($SectorSize * $i) - 2
					$FixupEntry = $MftRecord[$SourceOffset..($SourceOffset + 1)]
					
					if ($null -eq (Compare-Object $MftRecord[$TargetOffset..($TargetOffset + 1)] $FixupSignature)) {
						$MftRecord[$TargetOffset] = $FixupEntry[0]
						$MftRecord[($TargetOffset + 1)] = $FixupEntry[1]
					}
					else {
						
						
						return $False
					}
				}
			}

			
			
			
			while (
				($null -ne (Compare-Object ($AttributeTypeId = $MftRecord[$NextAttributeOffset..($NextAttributeOffset + 0x03)]) $EOF_SIG)) `
				-and ($NextAttributeOffset -lt $EntrySizeUsed)
			) {
				
				
				$AttributeLength = [BitConverter]::ToUInt32($MftRecord, ($NextAttributeOffset + 0x04))
				$AttributeResident = $null -eq (Compare-Object $MftRecord[($NextAttributeOffset + 0x08)] $NULL_BYTE) 
				[int]$AttributeNameLength = $MftRecord[($NextAttributeOffset + 0x09)] * 2 
				$AttributeNameOffset = [BitConverter]::ToUInt16($MftRecord, ($NextAttributeOffset + 0x0A))
				$AttributeFlags = $MftRecord[($NextAttributeOffset + 0x0C)..($NextAttributeOffset + 0x0D)]
				$AttributeId = [BitConverter]::ToUInt16($MftRecord, ($NextAttributeOffset + 0x0E))

				if ($AttributeNameLength -gt 0) {
					$AttributeNameStart = $NextAttributeOffset + $AttributeNameOffset
					$AttributeNameEnd = $AttributeNameStart + $AttributeNameLength - 1 
					$AttributeName = [Text.UnicodeEncoding]::Unicode.GetString($MftRecord[$AttributeNameStart..$AttributeNameEnd])
				}
				else {
					$AttributeName = $null
				}

				
				if ($AttributeResident) {
					$AttributeContentSize = [BitConverter]::ToUInt32($MftRecord, ($NextAttributeOffset + 0x10))
					$AttributeContentOffset = [BitConverter]::ToUInt16($MftRecord, ($NextAttributeOffset + 0x14))
					$AttributeContentStart = $NextAttributeOffset + $AttributeContentOffset
					$AttributeContent = $MftRecord[($AttributeContentStart)..($AttributeContentStart + $AttributeContentSize -1)] 
				}
				else {
				    $AttributeStartingVcn = $MftRecord[($NextAttributeOffset + 0x10)..($NextAttributeOffset + 0x17)]
					$AttributeEndingVcn = $MftRecord[($NextAttributeOffset + 0x18)..($NextAttributeOffset + 0x1F)]
					$AttributeRunlistOffset = [BitConverter]::ToUInt16($MftRecord, ($NextAttributeOffset + 0x20))
					$AttributeCompressionUnitSize = [BitConverter]::ToUInt16($MftRecord, ($NextAttributeOffset + 0x22))
					$AttributeSizeAllocated = [BitConverter]::ToUInt64($MftRecord, ($NextAttributeOffset + 0x28))
					$AttributeSizeActual = [BitConverter]::ToUInt64($MftRecord, ($NextAttributeOffset + 0x30))
					$AttributeSizeInit = [BitConverter]::ToUInt64($MftRecord, ($NextAttributeOffset + 0x38))

					$AttributeRunlistStart = $NextAttributeOffset + $AttributeRunlistOffset
					$AttributeRunlistEnd = $NextAttributeOffset + $AttributeLength - 1 
					$AttributeContent = $MftRecord[$AttributeRunlistStart..$AttributeRunlistEnd]
				}

				
				
				
				$AttributeType = [BitConverter]::ToUInt32($AttributeTypeId, 0x00)
				switch ($AttributeType)  {
					0x10 { $ParsedMftRecord | Add-Member -MemberType NoteProperty -Name StdInfoEntry -Value (Parse-StdInfoEntry $AttributeContent $AttributeResident) }
					
					
					0x30 { 
						$FNEntry = Parse-FilenameEntry $AttributeContent $AttributeResident
						if ($null -eq $ParsedMftRecord.FilenameEntries) {
							$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name FilenameEntries -Value @(,$FNEntry) 
						}
						else {
							$ParsedMftRecord.FilenameEntries += $FNEntry
						}
					}
					0x40 { $ParsedMftRecord | Add-Member -MemberType NoteProperty -Name ObjectIdEntry -Value (Parse-ObjectIdEntry $AttributeContent $AttributeResident) }
					
					
					
					0x80 { 
						$DataEntry = Parse-DataEntry $AttributeContent $AttributeResident
						if ($null -eq $ParsedMftRecord.DataEntry) {
							$ParsedMftRecord | Add-Member -MemberType NoteProperty -Name DataEntry -Value @(,$DataEntry) 
						}
						else {
							$ParsedMftRecord.DataEntry += $DataEntry
						} 
					}
					
					
					
					
					
					default { }
				}
				
				
				$NextAttributeOffset = $NextAttributeOffset + $AttributeLength
			}

			
			
			
			$first_fn = $true
			foreach ($FilenameEntry in $ParsedMftRecord.FilenameEntries) {
				
				$out = $ParsedMftRecord.PsObject.Copy()

				
				$out.FilenameEntries = $FilenameEntry

				if ($($ParsedMftRecord.DataEntry).Count -gt 1) {
					if ($first_fn) {
						$first_fn = $false 
						foreach ($DataEntry in $ParsedMftRecord.DataEntry) {
							$out_data = $out.PsObject.Copy()
							$out_data.DataEntry = $DataEntry

							$out_data
						}
						
						continue
					}
					else {
						$out.DataEntry = $out.DataEntry[0]
					}
					
				}

				$out
			}
		}
	}
	
	function ConvertTo-ReadableSize {
		Param(
			[Parameter(Mandatory=$true, Position=0)]
				$Value
		)
		$labels = @("bytes","KB","MB","GB","TB","PB")
		$runs = 0

		while ((($temp = ($Value / 1024)) -ge 1) -and (($runs + 1) -lt $labels.Count)) {
			$runs += 1
			$Value = $temp
		}

		$o = "" | Select-Object Value, Label
		$o.Value = $Value
		$o.Label = $labels[$runs]
		$o
	}

	if (($MyInvocation.BoundParameters).ContainsKey("Disk")) { 
		$DiskDeviceIds = @(,[String]::Format("\\.\PHYSICALDRIVE{0}", $Disk))
	}
	else {
		$DiskDeviceIds = Get-WmiObject -Class Win32_DiskDrive | Select-Object -ExpandProperty DeviceID
	}

	
	[byte[]]$MBR_SIG = 0x55, 0xAA
	[byte[]]$NTFS_SIG = 0x4E, 0x54, 0x46, 0x53, 0x20, 0x20, 0x20, 0x20
    [byte[]]$EmptyEntry = 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
}

     

PROCESS {
	foreach ($DiskDeviceId in $DiskDeviceIds) {
		Write-Verbose "Starting to process disk $DiskDeviceId"
		
		$DeviceIdFilter = [String]::Format("DeviceId = '{0}'", ($DiskDeviceId -replace '\\', '\\'))
		$DeviceWmiObject = Get-WmiObject -Class Win32_DiskDrive -Filter $DeviceIdFilter

		
		$SectorSize = $DeviceWmiObject | Select-Object -ExpandProperty BytesPerSector
		Write-Verbose ("Disk sector size is 0x{0:X} ({0}) bytes" -f $SectorSize)
	
		Write-Verbose "Grabbing first sector and analyzing master boot record."
		$RawStream = Open-RawStream -Path ($DeviceWmiObject | Select-Object -ExpandProperty Name)
		
		
		
		
		[byte[]]$ByteBuffer = Read-FromRawStream -Stream $RawStream -Length $SectorSize -Offset 0
	
		
		
		if ($null -ne (Compare-Object $ByteBuffer[510..511] $MBR_SIG)) {
			Write-Verbose "Provided device does not have master boot record in the first sector."
			continue
		}

		
		$PartitionEntries = $ByteBuffer[446..461], 
							$ByteBuffer[462..477], 
							$ByteBuffer[478..493], 
							$ByteBuffer[494..509]
		
		$PartitionCount = ($PartitionEntries | Where-Object { $null -ne (Compare-Object $_ $EmptyEntry)} ).Count
		$PartitionStats = $PartitionEntries | Get-PartitionStats
        Write-Verbose ("Found {0} partition entries.`r`n{1}" `
            -f $PartitionCount, `
            ($PartitionStats | Where-Object { $_.Type -ne "Empty" } | Format-Table -AutoSize | Out-String))

		if (($MyInvocation.BoundParameters).ContainsKey("Partition")) {
			$PartitionIds  = @(,$Partition)
		}
		else {
			$PartitionIds = @(0..($PartitionCount - 1)) 
		}

		foreach ($PartitionId in $PartitionIds) {
			Write-Verbose ""
			Write-Verbose "Starting to process partition entry $PartitionId."
            
            
            if ((($PartitionStats[$PartitionId]).Type -ne "NTFS") -and `
				(($PartitionStats[$PartitionId]).Type -inotmatch "extended") -and `
				(($PartitionStats[$PartitionId]).Type -inotmatch "GPT")
			) {
                Write-Error ("Non-NTFS primary partition selected. Partition {0} is of type {1}." `
                    -f $PartitionId, $($PartitionStats[$PartitionId].Type))
                continue
            }
			elseif (($PartitionStats[$PartitionId]).Type -imatch "extended") {
				Write-Error ("Partition {0} is an extended partition, which is not yet supported." -f $PartitionId)
				continue
			}
			elseif (($PartitionStats[$PartitionId]).Type -imatch "GPT") { 
				Write-Error ("Partition entry {0} points to a GPT partition table, which is not yet supported." -f $PartitionId)
				continue
			}
			
			
			
			$Offset = [int](($PartitionStats[$PartitionId]).FirstSector) * $SectorSize
			
			
			$ByteBuffer = Read-FromRawStream -Stream $RawStream -Length $SectorSize -Offset $Offset

			
			if ($null -ne (Compare-Object $ByteBuffer[0x03..0x0A] $NTFS_SIG)) {
				Write-Error ("Sector at offset 0x{0:X} is not an NTFS boot sector." -f $Offset)
				continue
			}
            Write-Verbose ("    Verified partition entry {0} refers to an NTFS partition." -f $PartitionId)

			

			
			$PartitionBytesPerSector = [BitConverter]::ToUInt16($ByteBuffer, 0x0B)
			[int]$PartitionSectorsPerCluster = $ByteBuffer[0x0D]
			Write-Verbose ("    Partition has {0} bytes per sector and {1} sectors per cluster." -f $PartitionBytesPerSector, $PartitionSectorsPerCluster)
			
			$MftLogicalClusterNumber = [BitConverter]::ToUInt64($ByteBuffer, 0x30)
			$MftLogicalOffset = $PartitionBytesPerSector * $PartitionSectorsPerCluster * $MftLogicalClusterNumber
			Write-Verbose ("    MFT is 0x{0:X} ({0}) bytes into the partition." -f $MftLogicalOffset)

			
			
			
			[int]$SizeOfFileRecord = $ByteBuffer[0x40]
			if ($SizeOfFileRecord -ge 0x80) {
				$SizeOfFileRecord = [Math]::Pow(2, (($SizeOfFileRecord -bxor 0xFF) + 1)) 
			}
			else {
				$SizeOfFileRecord = $SizeOfFileRecord * $PartitionSectorsPerCluster * $PartitionBytesPerSector
			}
			Write-Verbose ("    MFT file records are 0x{0:X} ({0}) bytes long." -f [int]$SizeOfFileRecord)

			
			[int]$SizeOfIndexRecord = $ByteBuffer[0x44]
			if ($SizeOfIndexRecord -ge 0x80) {
				$SizeOfIndexRecord = [Math]::Pow(2, (($SizeOfIndexRecord -bxor 0xFF) + 1)) 
			}
			else {
				$SizeOfIndexRecord = $SizeOfIndexRecord * $PartitionSectorsPerCluster * $PartitionBytesPerSector
			}
			Write-Verbose ("    MFT index records are 0x{0:X} ({0}) bytes long." -f [int]$SizeOfIndexRecord)

			
			
			
			
			[byte[]]$FileRecordByteBuffer = Read-FromRawStream -Stream $RawStream -Length $SizeOfFileRecord -Offset ($Offset + $MftLogicalOffset)

			
			Write-Verbose "    Parsing the MFT's self-referential entry."
			$MftMetadata = Parse-MftRecord $FileRecordByteBuffer

			foreach ($DataRun in $MftMetadata.DataEntry.DATA_Runlist) { 
				
				
				if ($DataRun.Run_Index -ge 0) {
					
					
					
					$RunIndex = $DataRun.Run_Index
					$RunLength = $DataRun.Run_Length * $PartitionBytesPerSector * $PartitionSectorsPerCluster
					$RunStart = $Offset + ($DataRun.Run_Start * $PartitionBytesPerSector * $PartitionSectorsPerCluster)
					$RunEnd   = $RunStart + $RunLength
					$RunPointer = $RunStart
					
					
					
					
					
					$RunFileOffset = ((
						$MftMetadata.DataEntry.DATA_Runlist | `
						Where-Object { $_.Run_Index -in (0..$RunIndex) } | `
						Select-Object -ExpandProperty Run_Length | `
						Measure-Object -Sum
					).Sum * $PartitionBytesPerSector * $PartitionSectorsPerCluster) - $RunLength
					

					
					
					while ($RunPointer -lt $RunEnd) {
						
						$EntryNumber = ($RunFileOffset + ($RunPointer - $RunStart)) / $SizeOfFileRecord
							
						if ($MftAttributes = Parse-MftRecord (Read-FromRawStream -Stream $RawStream -Length $SizeOfFileRecord -Offset $RunPointer)) {
							foreach ($MftAttribute in $MftAttributes) {
								
								
								$OutputRecord = New-Object psobject -Property ([ordered]@{
									'Device' = $DiskDeviceId;
									'Partition' = $PartitionId;
									'Entry Number' = $EntryNumber; 
									'Sequence Number' = $MftAttribute.SequenceValue;
									'File Name' = $MftAttribute.FilenameEntries.FN_Name;
									'Active' = (($MftAttribute.Flags -band 1) -gt 0).ToString();
									'Link Count' = $MftAttribute.LinkCount;
									'Entry Type' = if(($MftAttribute.Flags -band 2) -eq 0) { 'File' } else { 'Directory' };
									'Log Sequence Number' = ('{0:D}' -f $MftAttribute.LogSequenceNumber);
									'StdInfo: Modified' = ('{0:s}' -f $MftAttribute.StdInfoEntry.SI_Modified); 
									'StdInfo: Accessed' = ('{0:s}' -f $MftAttribute.StdInfoEntry.SI_Accessed); 
									'StdInfo: Entry Modified' = ('{0:s}' -f $MftAttribute.StdInfoEntry.SI_EntryModified); 
									'StdInfo: Created' = ('{0:s}' -f $MftAttribute.StdInfoEntry.SI_Created); 
									'StdInfo: USN' = ('{0:D}' -f $MftAttribute.StdInfoEntry.SI_UpdateSequenceNumber);
									'Filename: Modified' = ('{0:s}' -f $MftAttribute.FilenameEntries.FN_Modified); 
									'Filename: Accessed' = ('{0:s}' -f $MftAttribute.FilenameEntries.FN_Accessed); 
									'Filename: Entry Modified' = ('{0:s}' -f $MftAttribute.FilenameEntries.FN_EntryModified); 
									'Filename: Created' = ('{0:s}' -f $MftAttribute.FilenameEntries.FN_Created); 
									'Filename: Namespace' = $MftAttribute.FilenameEntries.FN_NameSpace;
									'Filename: Parent Entry' = ('{0:D}' -f $MftAttribute.FilenameEntries.FN_ParentEntry);
									'Filename: Parent Sequence Number' = ('{0:D}' -f $MftAttribute.FilenameEntries.FN_ParentSeq);
									'Filename: Actual Size' = ('{0:D}' -f $MftAttribute.FilenameEntries.FN_RealSize);
									'Filename: Allocated Size' = ('{0:D}' -f $MftAttribute.FilenameEntries.FN_AllocatedSize);
									'Data: Resident' = $MftAttribute.DataEntry.DATA_Resident;
									'Data: Actual Size' = ('{0:D}' -f $MftAttribute.DataEntry.DATA_SizeActual);
									'Data: Allocated Size' = ('{0:D}' -f $MftAttribute.DataEntry.DATA_SizeAllocated);
									'Data: Stream Name' = $MftAttribute.DataEntry.DATA_StreamName;
									'Data: Resident Data' = ($MftAttribute.DataEntry.DATA_ResidentData | Out-String).Trim();
									'Data: Data Runs' = ($MftAttribute.DataEntry.DATA_Runlist | Format-Table -AutoSize | Out-String).Trim()
								})

								$OutputRecord
							}
						}

						
						$RunPointer += $SizeOfFileRecord
					}
				}
			}
		}
	}
}

END {
	
	$RawStream.Close()
}










function Test-IsFileBinary
{
	[CmdletBinding()]
	[OutputType('System.Boolean')]
	Param(
		[Parameter(
			Position=0,
			Mandatory=$true,
			HelpMessage="Path to file which should be checked")]
		[ValidateScript({
			if(Test-Path -Path $_ -PathType Leaf)
			{
				return $true
			}
			else 
			{
				throw "Enter a valid file path!"	
			}
		})]
		[String]$FilePath
	)

	Begin{
		
	}

	Process{
		
		$Encoding = [String]::Empty

        
        $ByteCount = 1024
        		
		$ByteArray = Get-Content -Path $FilePath -Encoding Byte -TotalCount $ByteCount

        if($ByteArray.Count -ge $ByteCount)
        {
            Write-Verbose -Message "Could only read $($ByteArray.Count)/$ByteCount Bytes. File "
        }
      
        if(($ByteArray.Count -ge 4) -and (("{0:X}{1:X}{2:X}{3:X}" -f $ByteArray) -eq "FFFE0000"))
		{
			Write-Verbose -Message "UTF-32 detected!"
			$Encoding = "UTF-32"
		}
		elseif(($ByteArray.Count -ge 4) -and (("{0:X}{1:X}{2:X}{3:X}" -f $ByteArray) -eq "0000FEFF"))
		{
			Write-Verbose -Message "UTF-32 BE detected!"
			$Encoding = "UTF-32 BE"
		}
        elseif(($ByteArray.Count -ge 3) -and (("{0:X}{1:X}{2:X}" -f $ByteArray) -eq "EFBBBF"))
		{
			Write-Verbose -Message "UTF-8 detected!"
			$Encoding = "UTF-8"
		}
		elseif(($ByteArray.Count -ge 2) -and (("{0:X}{1:X}" -f $ByteArray) -eq "FFFE"))
		{
			Write-Verbose -Message "UTF-16 detected!"
			$Encoding = "UTF-16"
		}
		elseif(($ByteArray.Count -ge 2) -and (("{0:X}{1:X}" -f $ByteArray) -eq "FEFF"))
		{
            Write-Verbose "UTF-16 BE detected!"
			$Encoding = "UTF-16 BE"
		}

		if(-not([String]::IsNullOrEmpty($Encoding)))
		{
            Write-Verbose -Message "File is text encoded!"
			return $false
		}

		
		
		

		

		if($byteArray -contains 0 )
		{
			Write-Verbose -Message "File is a binary!"
			return $true
		}

        Write-Verbose -Message "File should be ASCII encoded!"
		return $false
	}

	End{
		
	}
}
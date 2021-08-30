function New-Password
{

	[CmdletBinding()]
	PARAM
	(
		[ValidateNotNull()]
		[int]$Length = 12,
        [ValidateRange(1,256)]
        [Int]$Count = 1
	)

	BEGIN
	{
		
		$PasswordCharCodes = { 33..126 }.invoke()


        
        
		
		34, 39, 46, 47, 49, 60, 62, 96, 48, 79, 108, 124 | ForEach-Object { [void]$PasswordCharCodes.Remove($_) }
		$PasswordChars = [char[]]$PasswordCharCodes
	}

	PROCESS
	{
        1..$count | ForEach-Object {
            
		    IF ($Length -gt 4)
		    {

			    DO
			    {
				    
				    $NewPassWord = $(foreach ($i in 1..$length) { Get-Random -InputObject $PassWordChars }) -join ''
			    }
			    UNTIL (
			    
			    ($NewPassword -cmatch '[A-Z]') -and
			    ($NewPassWord -cmatch '[a-z]') -and
			    ($NewPassWord -imatch '[0-9]') -and
			    ($NewPassWord -imatch '[^A-Z0-9]')
			    )
		    }
            
		    ELSE
		    {
			    $NewPassWord = $(foreach ($i in 1..$length) { Get-Random -InputObject $PassWordChars }) -join ''
		    }

		    
		    Write-Output $NewPassword
        }
	} 
	END
	{
        
		Remove-Variable -Name NewPassWord -ErrorAction 'SilentlyContinue'
	} 
} 
function Register-PSFTypeSerializationData
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTypeSerializationData')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string[]]
		$TypeData,
		
		[string]
		$Path = (Get-PSFConfigValue -FullName 'PSFramework.Serialization.WorkingDirectory' -Fallback $script:path_typedata)
	)
	
	begin
	{
		if (-not (Test-Path $Path -PathType Container))
		{
			$null = New-Item -Path $Path -ItemType Directory -Force
		}
	}
	process
	{
		foreach ($item in $TypeData)
		{
			$name = $item -split "`n" | Select-String "<Name>(.*?)</Name>" | Where-Object { $_ -notmatch "<Name>Deserialized.|<Name>PSStandardMembers</Name>|<Name>SerializationData</Name>" } | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value }
			$fullName = Join-Path $Path.Trim "$($name).Types.ps1xml"
			
			$item | Set-Content -Path $fullName -Force -Encoding UTF8
			Update-TypeData -AppendPath $fullName
		}
	}
	end
	{
	
	}
}
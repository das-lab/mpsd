function Get-PSFTypeSerializationData
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTypeSerializationData')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[object[]]
		$InputObject,
		
		[ValidateSet('Grouped','SingleItem')]
		[string]
		$Mode = "Grouped",
		
		[switch]
		$Fragment,
		
		[string]
		$Serializer = "PSFramework.Serialization.SerializationTypeConverter",
		
		[string]
		$Method = "GetSerializationData"
	)
	
	begin
	{
		
		function Get-XmlHeader
		{
			
			Param (
				
			)
			
			@"
<?xml version="1.0" encoding="utf-8"?>
<Types>

"@
		}
		
		function Get-XmlBody
		{
			
			Param (
				[string]
				$Type,
				
				[string]
				$Serializer,
				
				[string]
				$Method
			)
			
			@"

  <!-- $Type -->
  <Type>
    <Name>Deserialized.$Type</Name>
    <Members>
      <MemberSet>
        <Name>PSStandardMembers</Name>
        <Members>
          <NoteProperty>
            <Name>
              TargetTypeForDeserialization
            </Name>
            <Value>
              $Type
            </Value>
          </NoteProperty>
        </Members>
      </MemberSet>
    </Members>
  </Type>
  <Type>
    <Name>$Type</Name>
    <Members>
      <CodeProperty IsHidden="true">
        <Name>SerializationData</Name>
        <GetCodeReference>
          <TypeName>$Serializer</TypeName>
          <MethodName>$Method</MethodName>
        </GetCodeReference>
      </CodeProperty>
    </Members>
    <TypeConverter>
      <TypeName>$Serializer</TypeName>
    </TypeConverter>
  </Type>

"@
		}
		
		function Get-XmlFooter
		{
			
			Param (
				
			)
			@"
</Types>
"@
		}
		
		
		$types = @()
		if ($Mode -eq 'Grouped')
		{
			if (-not $Fragment) { $xml = Get-XmlHeader }
			else { $xml = "" }
		}
	}
	process
	{
		foreach ($item in $InputObject)
		{
			if ($null -eq $item) { continue }
			$type = $null
			if ($res = $item -as [System.Type]) { $type = $res }
			else { $type = $item.GetType() }
			
			if ($type -in $types) { continue }
			
			switch ($Mode)
			{
				'Grouped' { $xml += Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName }
				'SingleItem'
				{
					if (-not $Fragment)
					{
						$xml = Get-XmlHeader
						$xml += Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName
						$xml += Get-XmlFooter
						$xml
					}
					else
					{
						Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName
					}
				}
			}
			
			$types += $type
		}
	}
	end
	{
		if ($Mode -eq 'Grouped')
		{
			if (-not $Fragment) { $xml += Get-XmlFooter }
			$xml
		}
	}
}
Register-PSFTeppScriptblock -Name PSFramework-Input-ObjectProperty -ScriptBlock {
	
	function Get-Property
	{
		[CmdletBinding()]
		param (
			$InputObject
		)
		
		if (-not $InputObject) { return @{ } }
		$properties = @{ }
		
		switch ($InputObject.GetType().FullName)
		{
			
			'System.Management.Automation.Language.CommandExpressionAst'
			{
				switch ($InputObject.Expression.GetType().Name)
				{
					'BinaryExpressionAst'
					{
						
						return @{ }
					}
					'VariableExpressionAst'
					{
						$members = Get-Variable -Name $InputObject.Expression.VariablePath.UserPath -ValueOnly -ErrorAction Ignore | Write-Output | Select-Object -First 1 | Get-Member -MemberType Properties
						foreach ($member in $members)
						{
							try
							{
								$typeString = $member.Definition.Split(" ")[0]
								$memberType = [type]$typeString
								$typeKnown = $true
							}
							catch
							{
								$memberType = $null
								$typeKnown = $false
							}
							
							$properties[$member.Name] = [pscustomobject]@{
								Name = $member.Name
								Type = $memberType
								TypeKnown = $typeKnown
							}
						}
						return $properties
					}
					'MemberExpressionAst'
					{
						try { $members = Get-Variable -Name $InputObject.Expression.Expression.VariablePath.UserPath -ValueOnly -ErrorAction Ignore | Where-Object $InputObject.Expression.Member.Value -ne $null | Select-Object -First 1 -ExpandProperty $InputObject.Expression.Member.Value -ErrorAction Ignore | Get-Member -MemberType Properties }
						catch { return $properties }
						foreach ($member in $members)
						{
							try
							{
								$typeString = $member.Definition.Split(" ")[0]
								$memberType = [type]$typeString
								$typeKnown = $true
							}
							catch
							{
								$memberType = $null
								$typeKnown = $false
							}
							
							$properties[$member.Name] = [pscustomobject]@{
								Name = $member.Name
								Type = $memberType
								TypeKnown = $typeKnown
							}
						}
						return $properties
					}
					'ArrayLiteralAst'
					{
						
						return @{ }
					}
				}
				
				if ($pipelineAst.PipelineElements[$inputIndex].Expression -and $pipelineAst.PipelineElements[0].Expression[0].VariablePath)
				{
					$properties += ((Get-Variable -Name $pipelineAst.PipelineElements[0].Expression[0].VariablePath.UserPath -ValueOnly) | Select-Object -First 1 | Get-Member -MemberType Properties).Name
				}
				
			}
			
			
			
			'System.Management.Automation.Language.CommandAst'
			{
				$command = Get-Command $InputObject.CommandElements[0].Value -ErrorAction Ignore
				if ($command -is [System.Management.Automation.AliasInfo]) { $command = $command.ResolvedCommand }
				if (-not $command) { return $properties }
				
				foreach ($type in $command.OutputType.Type)
				{
					foreach ($member in $type.GetMembers("Instance, Public"))
					{
						
						if (-not ($member.MemberType -band 20)) { continue }
						
						$properties[$member.Name] = [pscustomobject]@{
							Name = $member.Name
							Type = $null
							TypeKnown = $true
						}
						if ($member.PropertyType) { $properties[$member.Name].Type = $member.PropertyType }
						else { $properties[$member.Name].Type = $member.FieldType }
					}
					
					foreach ($propertyExtensionItem in ([PSFramework.TabExpansion.TabExpansionHost]::InputCompletionTypeData[$type.FullName]))
					{
						$properties[$propertyExtensionItem.Name] = $propertyExtensionItem
					}
				}
				
				
				foreach ($propertyExtensionItem in ([PSFramework.TabExpansion.TabExpansionHost]::InputCompletionCommandData[$command.Name]))
				{
					$properties[$propertyExtensionItem.Name] = $propertyExtensionItem
				}
				
				
				return $properties
			}
			
			
			
			default { return @{ } }
		}
	}
	
	function Update-Property
	{
		[CmdletBinding()]
		param (
			[Hashtable]
			$Property,
			
			$Step
		)
		
		$properties = @{ }
		
		if ($Step.ExpandProperty)
		{
			if (-not ($Property[$Step.ExpandProperty])) { return $properties }
			
			$expanded = $Property[$Step.ExpandProperty]
			if (-not $expanded.TypeKnown) { return $properties }
			
			foreach ($member in $expanded.Type.GetMembers("Instance, Public"))
			{
				
				if (-not ($member.MemberType -band 20)) { continue }
				
				$properties[$member.Name] = [pscustomobject]@{
					Name = $member.Name
					Type = $null
					TypeKnown = $true
				}
				if ($member.PropertyType) { $properties[$member.Name].Type = $member.PropertyType }
				else { $properties[$member.Name].Type = $member.FieldType }
			}
			
			foreach ($propertyExtensionItem in ([PSFramework.TabExpansion.TabExpansionHost]::InputCompletionTypeData[$expanded.Type.FullName]))
			{
				$properties[$propertyExtensionItem.Name] = $propertyExtensionItem
			}
			
			return $properties
		}
		
		
		
		if ($Step.KeepInputObject) { $properties = $Property.Clone() }
		$filterProperties = $Step.Properties | Where-Object Kind -eq "Property"
		
		
		if (-not $Step.KeepInputObject)
		{
			:main foreach ($propertyItem in $Property.Values)
			{
				
				foreach ($exclusion in $Step.Excluded)
				{
					if ($propertyItem.Name -like $exclusion) { continue main }
				}
				
				
				foreach ($stepProperty in $filterProperties)
				{
					if ($propertyItem.Name -like $stepProperty.Name)
					{
						$properties[$propertyItem.Name] = $propertyItem
						continue main
					}
				}
			}
		}
		
		
		
		:main foreach ($stepProperty in $Step.Properties)
		{
			switch ($stepProperty.Kind)
			{
				'Property'
				{
					if ($stepProperty.Filter) { continue main }
					if ($properties[$stepProperty.Name]) { continue main }
					
					foreach ($exclusion in $Step.Excluded)
					{
						if ($stepProperty.Name -like $exclusion) { continue main }
					}
					
					$properties[$stepProperty.Name] = [PSCustomObject]@{
						Name = $stepProperty.Name
						Type = $null
						TypeKnown = $false
					}
					continue main
				}
				'CalculatedProperty'
				{
					if ($properties[$stepProperty.Name]) { continue main }
					
					$properties[$stepProperty.Name] = [PSCustomObject]@{
						Name = $stepProperty.Name
						Type = $null
						TypeKnown = $false
					}
					continue main
				}
				'ScriptProperty'
				{
					if ($properties[$stepProperty.Name]) { continue main }
					
					$properties[$stepProperty.Name] = [PSCustomObject]@{
						Name = $stepProperty.Name
						Type = $null
						TypeKnown = $false
					}
					continue main
				}
				'AliasProperty'
				{
					if ($properties[$stepProperty.Name]) { continue main }
					
					$properties[$stepProperty.Name] = [PSCustomObject]@{
						Name = $stepProperty.Name
						Type = $null
						TypeKnown = $false
					}
					if ($properties[$stepProperty.Target].TypeKnown)
					{
						$properties[$stepProperty.Name].Type = $properties[$stepProperty.Target].Type
						$properties[$stepProperty.Name].TypeKnown = $properties[$stepProperty.Target].TypeKnown
					}
					
					continue main
				}
			}
		}
		
		$properties
	}
	
	function Read-SelectObject
	{
		[CmdletBinding()]
		param (
			[System.Management.Automation.Language.CommandAst]
			$Ast,
			
			[string]
			$CommandName = 'Select-Object'
		)
		
		$results = [pscustomobject]@{
			Ast			    = $Ast
			BoundParameters = @()
			Property	    = @()
			ExcludeProperty = @()
			ExpandProperty  = ''
			ScriptProperty  = @()
			AliasProperty   = @()
			KeepInputObject = $false
		}
		
		
		if ($Ast.CommandElements.Count -gt 1)
		{
			$index = 1
			$parameterName = ''
			$position = 0
			while ($index -lt $Ast.CommandElements.Count)
			{
				$element = $Ast.CommandElements[$index]
				switch ($element.GetType().FullName)
				{
					'System.Management.Automation.Language.CommandParameterAst'
					{
						$parameterName = $element.ParameterName
						if ($parameterName -like "k*") { $results.KeepInputObject = $true }
						$results.BoundParameters += $element.ParameterName
						break
					}
					'System.Management.Automation.Language.StringConstantExpressionAst'
					{
						if (-not $parameterName)
						{
							switch ($position)
							{
								0 { $results.Property = $element }
								1 { $results.AliasProperty = $element }
								2 { $results.ScriptProperty = $element }
							}
							$position = $position + 1
						}
						
						if ($parameterName -like "pr*") { $results.Property = $element }
						if ($parameterName -like "exp*") { $results.ExpandProperty = $element.Value }
						if ($parameterName -like "exc*") { $results.ExcludeProperty = $element.Value }
						if ($parameterName -like "a*") { $results.AliasProperty = $element }
						if ($parameterName -like "scriptp*") { $results.ScriptProperty = $element }
						$parameterName = ''
						break
					}
					'System.Management.Automation.Language.ArrayLiteralAst'
					{
						if (-not $parameterName)
						{
							switch ($position)
							{
								0 { $results.Property = $element.Elements }
								1 { $results.AliasProperty = $element.Elements }
								2 { $results.ScriptProperty = $element.Elements }
							}
							$position = $position + 1
						}
						
						if ($parameterName -like "pr*") { $results.Property = $element.Elements }
						if ($parameterName -like "exp*") { $results.ExpandProperty = $element.Elements.Value }
						if ($parameterName -like "exc*") { $results.ExcludeProperty = $element.Elements.Value }
						if ($parameterName -like "a*") { $results.AliasProperty = $element.Elements }
						if ($parameterName -like "scriptp*") { $results.ScriptProperty = $element.Elements }
						
						$parameterName = ''
						break
					}
					'System.Management.Automation.Language.ConstantExpressionAst'
					{
						if (-not $parameterName)
						{
							switch ($position)
							{
								0 { $results.Property = $element }
								1 { $results.AliasProperty = $element }
								2 { $results.ScriptProperty = $element }
							}
							$position = $position + 1
						}
						
						if ($parameterName -like "pr*") { $results.Property = $element }
						if ($parameterName -like "exp*") { $results.ExpandProperty = $element.Value.ToString() }
						if ($parameterName -like "exc*") { $results.ExcludeProperty = $element.Value.ToString() }
						if ($parameterName -like "a*") { $results.AliasProperty = $element }
						if ($parameterName -like "scriptp*") { $results.ScriptProperty = $element }
						$parameterName = ''
						break
					}
					'System.Management.Automation.Language.HashtableAst'
					{
						if (-not $parameterName)
						{
							switch ($position)
							{
								0 { $results.Property = $element }
								1 { $results.AliasProperty = $element }
								2 { $results.ScriptProperty = $element }
							}
							$position = $position + 1
						}
						
						if ($parameterName -like "pr*") { $results.Property = $element }
						if ($parameterName -like "a*") { $results.AliasProperty = $element }
						if ($parameterName -like "scriptp*") { $results.ScriptProperty = $element }
						$parameterName = ''
						break
					}
					default
					{
						$parameterName = ''
					}
				}
				$index = $index + 1
			}
		}
		
		
		
		$resultsProcessed = [pscustomobject]@{
			HasIncludeFilter = $false
			RawResult	     = $results
			Properties	     = @()
			Excluded		 = $results.ExcludeProperty
			ExpandProperty   = $results.ExpandProperty
			KeepInputObject  = $results.KeepInputObject
		}
		
		switch ($CommandName)
		{
			
			'Select-Object'
			{
				
				foreach ($element in $results.Property)
				{
					switch ($element.GetType().FullName)
					{
						'System.Management.Automation.Language.HashtableAst'
						{
							try
							{
								$resultsProcessed.Properties += [pscustomobject]@{
									Name = ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$|^L$|^Label$' | Select-Object -First 1).Item2.PipelineElements[0].Expression.Value
									Kind = "CalculatedProperty"
									Type = "Unknown"
									Filter = $false
								}
							}
							catch { }
						}
						default
						{
							if ($element.Value -match "\*") { $resultsProcessed.HasIncludeFilter = $true }
							
							$resultsProcessed.Properties += [pscustomobject]@{
								Name = $element.Value.ToString()
								Kind = "Property"
								Type = "Inherited"
								Filter = $element.Value -match "\*"
							}
						}
					}
				}
				
			}
			
			
			
			'Select-PSFObject'
			{
				
				foreach ($element in $results.Property)
				{
					switch ($element.GetType().FullName)
					{
						'System.Management.Automation.Language.HashtableAst'
						{
							try
							{
								$resultsProcessed.Properties += [pscustomobject]@{
									Name = ($element.KeyValuePairs | Where-Object Item1 -Match '^N$|^Name$|^L$|^Label$' | Select-Object -First 1).Item2.PipelineElements[0].Expression.Value
									Kind = "CalculatedProperty"
									Type = "Unknown"
									Filter = $false
								}
							}
							catch { }
						}
						default
						{
							try { $parameterItem = ([PSFramework.Parameter.SelectParameter]$element.Value).Value }
							catch { continue }
							
							if ($parameterItem -is [System.String])
							{
								if ($parameterItem -match "\*") { $resultsProcessed.HasIncludeFilter = $true }
								
								$resultsProcessed.Properties += [pscustomobject]@{
									Name   = $parameterItem
									Kind   = "Property"
									Type   = "Inherited"
									Filter = $parameterItem -match "\*"
								}
							}
							else
							{
								$resultsProcessed.Properties += [pscustomobject]@{
									Name   = $parameterItem
									Kind   = "CalculatedProperty"
									Type   = "Unknown"
									Filter = $false
								}
							}
						}
					}
				}
				
				
				
				foreach ($scriptProperty in $results.ScriptProperty)
				{
					switch ($scriptProperty.GetType().FullName)
					{
						'System.Management.Automation.Language.HashtableAst'
						{
							foreach ($name in $scriptProperty.KeyValuePairs.Item1.Value)
							{
								$resultsProcessed.Properties += [pscustomobject]@{
									Name   = $name
									Kind   = "ScriptProperty"
									Type   = "Unknown"
									Filter = $false
								}
							}
						}
						default
						{
							try { $propertyValue = [PSFramework.Parameter.SelectScriptPropertyParameter]$scriptProperty.Value }
							catch { continue }
							
							$resultsProcessed.Properties += [pscustomobject]@{
								Name = $propertyValue.Value.Name
								Kind = "ScriptProperty"
								Type = "Unknown"
								Filter = $false
							}
						}
					}
				}
				
				
				
				foreach ($scriptProperty in $results.AliasProperty)
				{
					switch ($scriptProperty.GetType().FullName)
					{
						'System.Management.Automation.Language.HashtableAst'
						{
							foreach ($aliasPair in $scriptProperty.KeyValuePairs)
							{
								$resultsProcessed.Properties += [pscustomobject]@{
									Name = $aliasPair.Item1.Value
									Kind = "AliasProperty"
									Type = "Alias"
									Filter = $false
									Target = $aliasPair.Item2.PipelineElements.Expression.Value
								}
							}
						}
						default
						{
							try { $propertyValue = [PSFramework.Parameter.SelectAliasParameter]$scriptProperty.Value }
							catch { continue }
							
							$resultsProcessed.Properties += [pscustomobject]@{
								Name = $propertyValue.Aliases[0].Name
								Kind = "AliasProperty"
								Type = "Alias"
								Filter = $false
								Target = $propertyValue.Aliases[0].ReferencedMemberName
							}
						}
					}
				}
				
			}
			
		}
		
		
		$resultsProcessed
	}
	
	
	
	[System.Management.Automation.Language.PipelineAst]$pipelineAst = $commandAst.parent
	$index = $pipelineAst.PipelineElements.IndexOf($commandAst)
	
	
	if ($index -lt 1) { return }
	
	$inputIndex = $index - 1
	$steps = @{ }
	
	
	:outmain while ($true)
	{
		if ($pipelineAst.PipelineElements[$inputIndex].CommandElements)
		{
			
			$command = $null
			
			if ($pipelineAst.PipelineElements[$inputIndex].CommandElements[0].Value -eq "?") { $command = Get-Alias -Name "?" | Where-Object Name -eq "?" }
			else { $command = Get-Command $pipelineAst.PipelineElements[$inputIndex].CommandElements[0].Value -ErrorAction Ignore }
			if ($command -is [System.Management.Automation.AliasInfo]) { $command = $command.ResolvedCommand }
			if (-not $command) { return }
			
			switch ($command.Name)
			{
				'Where-Object'
				{
					$steps[$inputIndex] = [pscustomobject]@{
						Index = $inputIndex
						Skip  = $true
						Type  = 'Where'
					}
					$inputIndex = $inputIndex - 1
					continue outmain
				}
				'Tee-Object'
				{
					$steps[$inputIndex] = [pscustomobject]@{
						Index = $inputIndex
						Skip  = $true
						Type  = 'Tee'
					}
					$inputIndex = $inputIndex - 1
					continue outmain
				}
				'Sort-Object'
				{
					$steps[$inputIndex] = [pscustomobject]@{
						Index = $inputIndex
						Skip  = $true
						Type  = 'Sort'
					}
					$inputIndex = $inputIndex - 1
					continue outmain
				}
				
				'Select-Object'
				{
					$selectObject = Read-SelectObject -Ast $pipelineAst.PipelineElements[$inputIndex] -CommandName 'Select-Object'
					
					$steps[$inputIndex] = [pscustomobject]@{
						Index = $inputIndex
						Skip  = $false
						Type  = 'Select'
						Data  = $selectObject
					}
					
					if ($selectObject.HasIncludeFilter -or ($selectObject.Properties.Type -eq "Inherited") -or $selectObject.ExpandProperty)
					{
						$inputIndex = $inputIndex - 1
						continue outmain
					}
					break outmain
				}
				
				
				'Select-PSFObject'
				{
					$selectObject = Read-SelectObject -Ast $pipelineAst.PipelineElements[$inputIndex] -CommandName 'Select-PSFObject'
					
					$steps[$inputIndex] = [pscustomobject]@{
						Index = $inputIndex
						Skip  = $false
						Type  = 'PSFSelect'
						Data  = $selectObject
					}
					
					if ($selectObject.HasIncludeFilter -or ($selectObject.Properties.Type -eq "Inherited") -or $selectObject.ExpandProperty)
					{
						$inputIndex = $inputIndex - 1
						continue outmain
					}
					break outmain
				}
				
				default { break outmain }
			}
		}
		
		else
		{
			break
		}
	}
	
	
	
	if ($inputIndex -lt 0) { return }
	
	
	$properties = Get-Property -InputObject $pipelineAst.PipelineElements[$inputIndex]
	$inputIndex = $inputIndex + 1
	
	while ($inputIndex -lt $index)
	{
		
		if (-not $steps[$inputIndex]) { $inputIndex = $inputIndex + 1; continue }
		if ($steps[$inputIndex].Skip) { $inputIndex = $inputIndex + 1; continue }
		
		
		$properties = Update-Property -Property $properties -Step $steps[$inputIndex].Data
		
		$inputIndex = $inputIndex + 1
	}
	
	
	$properties.Keys | Sort-Object
}
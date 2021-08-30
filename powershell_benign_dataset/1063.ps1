











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldConvertToBase64
{
    $expectedValue = 'YAAxADIAMwA0ADUANgA3ADgAOQAwAC0APQBxAHcAZQByAHQAeQB1AGkAbwBwAFsAXQBcAGEAcwBkAGYAZwBoAGoAawBsADsAJwB6AHgAYwB2AGIAbgBtACwALgAvACAAfgAhAEAAIwAkACUAXgAmACoAKAApAF8AKwBRAFcARQBSAFQAWQBVAEkATwBQAHsAfQB8AEEAUwBEAEYARwBIAEoASwBMADoAIgBaAFgAQwBWAEIATgBNADwAPgA/AA=='
    $value = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./ ~!@
    
    $actualValue = ConvertTo-Base64 -Value $value
    
    Assert-Equal $expectedValue $actualValue
}

function Test-ShouldAcceptPipelineInput
{
    $result = ('Value1','Value2') | ConvertTo-Base64
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertTo-Base64 -Value 'Value1') $result[0]
    Assert-Equal (ConvertTo-Base64 -Value 'Value2') $result[1]
}

function Test-ShouldAcceptArrayInput
{
    $result = ConvertTo-Base64 -Value @('Value1','Value2')
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertTo-Base64 -Value 'Value1') $result[0]
    Assert-Equal (ConvertTo-Base64 -Value 'Value2') $result[1]
}

function Test-ShouldAllowDifferentEncoding
{
    $value = 'Value1'
    $result = $value | 
                    ConvertTo-Base64 -Encoding ([Text.Encoding]::ASCII) | 
                    ConvertFrom-Base64 -Encoding ([Text.Encoding]::ASCII)
    Assert-Equal $value $result
}

function Test-ShouldAllowEmptyString
{
    $result = ConvertTo-Base64 ''
    Assert-Equal '' $result
}

function Test-ShouldAllowNull
{
    $result = ConvertTo-Base64 $null
    Assert-Null $null
}

function Test-ShouldAllowNullFromPipeline
{
    $values = @('1', $null, '3')
    $result = $values | ConvertTo-Base64 
    Assert-NotNull $result
    Assert-Equal 3 $result.Count
    Assert-Null $result[1]
}

function Test-ShouldAllowNullInArray
{
    $result = ConvertTo-Base64 -Value @( $null, $null )
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Empty $result[0]
    Assert-Empty $result[1]
}


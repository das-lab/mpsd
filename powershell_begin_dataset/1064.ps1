











function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Test-ShouldConvertToBase64
{
    $value = 'YAAxADIAMwA0ADUANgA3ADgAOQAwAC0APQBxAHcAZQByAHQAeQB1AGkAbwBwAFsAXQBcAGEAcwBkAGYAZwBoAGoAawBsADsAJwB6AHgAYwB2AGIAbgBtACwALgAvACAAfgAhAEAAIwAkACUAXgAmACoAKAApAF8AKwBRAFcARQBSAFQAWQBVAEkATwBQAHsAfQB8AEEAUwBEAEYARwBIAEoASwBMADoAIgBaAFgAQwBWAEIATgBNADwAPgA/AA=='
    $expectedValue = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./ ~!@
    
    $actualValue = ConvertFrom-Base64 -Value $value
    
    Assert-Equal $expectedValue $actualValue
}

function Test-ShouldAcceptPipelineInput
{
    $result = ('VgBhAGwAdQBlADEA','VgBhAGwAdQBlADIA') | ConvertFrom-Base64
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA') $result[0]
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADIA') $result[1]
}

function Test-ShouldAcceptArrayInput
{
    $result = ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA','VgBhAGwAdQBlADIA'
    Assert-Equal 2 $result.Length
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADEA') $result[0]
    Assert-Equal (ConvertFrom-Base64 -Value 'VgBhAGwAdQBlADIA') $result[1]
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
    $result = ConvertFrom-Base64 ''
    Assert-Equal '' $result
}

function Test-ShouldAllowNull
{
    $result = ConvertFrom-Base64 $null
    Assert-Null $null
}

function Test-ShouldAllowNullFromPipeline
{
    $values = @('MQA=', $null, '', 'MwA=')
    $result = $values | ConvertFrom-Base64 
    Assert-NotNull $result
    Assert-Equal 4 $result.Count
    Assert-Null $result[1]
    Assert-Empty $result[2]
}

function Test-ShouldAllowNullInArray
{
    $result = ConvertFrom-Base64 -Value @( $null, $null )
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Empty $result[0]
    Assert-Empty $result[1]
}


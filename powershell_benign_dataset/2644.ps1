
function Copy-SqlLogins{

  [cmdletbinding()]
  param([parameter(Mandatory=$true)][string] $source
    ,[string] $ApplyTo
    ,[string[]] $logins
  )
  
  $smosource = new-object ('Microsoft.SqlServer.Management.Smo.Server') $source 	
  
  
  $so = new-object microsoft.sqlserver.management.smo.scriptingoptions
  $so.LoginSid = $true

  
  $outscript = @()
  
  
  if($logins){
    $matchstring = $logins -join '|'
    $loginsmo = $smosource.logins | Where-Object {$_.Name -match $logins -and $_.IsSystemObject -eq $false -and $_.Name -notlike 'NT*'}
  }
  else{
    $loginsmo = $smosource.logins | Where-Object {$_.IsSystemObject -eq $false -and $_.Name -notlike 'NT*'}
  }
  
  
  foreach($login in $loginsmo){
    
    $lscript = $login.Script($so) | Where-Object {$_ -notlike 'ALTER LOGIN*DISABLE'}
    $lscript = $lscript.Replace('/* For security reasons the login is created disabled and with a random password. */','').Trim() -join "`n"
    
    
    if($login.LoginType -eq 'SqlLogin'){
      
      $sql = "SELECT convert(varbinary(256),password_hash) as hashedpass FROM sys.sql_logins where name='"+$login.name+"'"
      $hashedpass = ($smosource.databases['tempdb'].ExecuteWithResults($sql)).Tables.hashedpass
      $passtring = Convert-SQLHashToString $hashedpass
      $rndpw = $lscript.Substring($lscript.IndexOf('PASSWORD'),$lscript.IndexOf(', SID')-$lscript.IndexOf('PASSWORD'))
      
      $lscript = $lscript.Replace($rndpw,"PASSWORD = $passtring hashed")
    }
    
    
    $outscript += '/****************************************************'
    $outscript += "Login script for $($login.Name)"
    $outscript += '****************************************************/'
    $outscript += "IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$($login.Name)')"
    $outscript += "DROP LOGIN [$($login.Name)];"
    $outscript += "$lscript;"
  }

  
  $outscript = $outscript.Replace('WITH',"`nWITH`n`t").Replace(',',"`n`t,")

  if($ApplyTo.Length -eq 0){
    return $outscript
  }else{
    $smotarget = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ApplyTo
    $smotarget.Databases['tempdb'].ExecuteNonQuery($outscript -join "`n")
    
  }
}

function Convert-SQLHashToString{
  param([parameter(Mandatory=$true)] $binhash)
  
  $outstring = '0x'
  $binhash | ForEach-Object {$outstring += ('{0:X}' -f $_).PadLeft(2, '0')}
  
  return $outstring
}




param (
  [ValidateSet("machine","user","process")]
  [string[]]$PathScope="machine",
  [switch]$RemoveAllOccurences
)


ForEach ($PathScopeItem in $PathScope)
{
  $AssembledNewPath = $NewPath = ''
  
  $pathstoremove = @([Environment]::GetEnvironmentVariable("PATH","$PathScopeItem").split(';') | Where { $_ -ilike "*\Program Files\Powershell\6*"})
  If (!$RemoveAllOccurences)
  {
    
    $pathstoremove = @($pathstoremove | sort-object | Select-Object -skiplast 1)
  }
  Write-Verbose "Reset-PWSHSystemPath: Found $($pathstoremove.count) paths to remove from $PathScopeItem path scope: $($Pathstoremove -join ', ' | out-string)"
  If ($pathstoremove.count -gt 0)
  {
    foreach ($Path in [Environment]::GetEnvironmentVariable("PATH","$PathScopeItem").split(';'))
    {
      
      If ($Path)
      {
        If ($pathstoremove -inotcontains "$Path")
        {
          [string[]]$Newpath += "$Path"
        }
      }
    }
    $AssembledNewPath = ($newpath -join(';')).trimend(';')
    $AssembledNewPath -split ';'
    [Environment]::SetEnvironmentVariable("PATH",$AssembledNewPath,"$PathScopeItem")
  }
}

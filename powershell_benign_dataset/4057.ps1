$cmdLets = (Get-Module pscx).ExportedCmdlets.Keys
$functions = (Get-Module pscx).ExportedFunctions.Keys
$cmdLetsAndFunctions = $cmdLets + $functions | Select -uniq | Sort-Object

$nounsAndCommands = @{}

foreach ( $cmdLet in ($cmdLetsAndFunctions) ) {

  $noun = $cmdLet.split('-')[1]

  if ( ! $noun ) {
    continue
  }

  $description = (get-help $cmdLet).synopsis.replace('PSCX Cmdlet: ','')

  
  
  
  
  
  
  
  
  
  

  $helpEntry = @{'name' = $cmdLet; 'description' = $description;}

  if ( ! $nounsAndCommands.ContainsKey($noun) ) {
    $nounsAndCommands[$noun] = @()
  }
  $nounsAndCommands[$noun] += $helpEntry
}

$output = ''


foreach($item in $nounsAndCommands.GetEnumerator() | Sort Name) {
  $noun = $item.Name
  $output += @'



'@ -f $noun
  foreach ($commandNameAndDescription in $nounsAndCommands[$noun]) {
    $output += @'


{1}


'@ -f $commandNameAndDescription.name, $commandNameAndDescription.description
  }
}

echo $output

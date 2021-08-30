properties {
  $x = $null
  $y = $null
  $z = $null
}

task default -depends TestRequiredVariables


task TestRequiredVariables `
  -description "This task shows how to make a variable required to run task. Run this script with -properties @{x = 1; y = 2; z = 3}" `
  -requiredVariables x, y, z `
{
}

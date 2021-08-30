

param ( [switch]$Force, [switch]$UseExistingMsi )

$script:Constants =  @{
    AccountName   = 'PowerShell'
    ProjectName   = 'powershell-f975h'
    TestImageName = "remotetestimage"
    MsiName       = "PSCore.msi"
    Token         = "" 
}







$dockerExe = get-command docker -ea silentlycontinue
if ( $dockerExe.name -ne "docker.exe" ) {
    throw "Cannot find docker, is it installed?"
}


$TestImage = docker images $Constants.TestImageName --format '{{.Repository}}'
if ( $TestImage -eq $Constants.TestImageName) 
{
    if ( $Force ) 
    {
        docker rmi $Constants.TestImageName
    }
    else
    {
        throw ("{0} already exists, use '-Force' to remove" -f $Constants.TestImageName)
    }
}

$TestImage = docker images $Constants.TestImageName --format '{{.Repository}}'
if ( $TestImage -eq $Constants.TestImageName) 
{
    throw ("'{0}' still exists, giving up" -f $Constants.TestImageName)
}



$MsiExists = test-path $Constants.MsiName
$msg = "{0} exists, use -Force to remove or -UseExistingMsi to use" -f $Constants.MsiName
if ( $MsiExists -and ! ($force -or $useExistingMsi)) 
{
    throw $msg
}


if ( $MsiExists -and $Force -and ! $UseExistingMsi ) 
{
    Remove-Item -force $Constants.MsiName
    $MsiExists = $false
}




if ( ! $MsiExists -and $UseExistingMsi )
{
    throw ("{0} does not exist" -f $Constants.MsiName)
}
elseif ( $MsiExists -and ! $UseExistingMsi ) 
{
    throw $msg
}


if ( ! (test-path $Constants.MsiName) )
{
    throw ("{0} does not exist, giving up" -f $Constants.MsiName)
}


Docker build --tag $Constants.TestImageName .

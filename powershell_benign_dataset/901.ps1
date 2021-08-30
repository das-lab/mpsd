$gitdirectory="<Replace with path to local Git repo>"
$webappname="mywebapp$(Get-Random)"

cd $gitdirectory


New-AzWebApp -Name $webappname


git push azure master

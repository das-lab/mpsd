











[CmdletBinding()]
param(
)


Set-StrictMode -Version Latest

& (Join-Path $PSSCriptRoot ..\Import-Carbon.ps1 -Resolve)

$deploymentWritersGroupName = 'DeploymentWriters'
$deploymnetReadersGroupName = 'DeploymentReaders'
$ccnetServiceUser = 'example.com\CCServiceUser'

Install-Group -Name $deploymentWritersGroupName `
              -Description 'Users allowed to write to the deployment share.' `
              -Members $ccnetServiceUser
Install-Group -Name $deploymnetReadersGroupName `
              -Description 'Users allowed to read the deployment share.' `
              -Members 'Everyone'

$websitePath = '\Path\to\website\directory'
Grant-Permission -Path $websitePath -Permission FullControl `
                 -Identity $deploymentWritersGroupName
Grant-Permission -Path $websitePath -Permission Read `
                 -Identity $deploymnetReadersGroupName

$deployShareName = 'Deploy'
Install-Share -Name $deployShareName `
              -Path $websitePath `
              -Description 'Share used by build server to deploy website changes.' `
              -FullAccess $deploymentWritersGroupName `
              -ReadAccess $deploymnetReadersGroupName


$sslCertPath = 'Path\to\SSL\certificate.cer'
$cert = Install-Certificate -Path $sslCertPath -StoreLocation LocalMachine -StoreName My
Set-SslCertificateBinding -ApplicationID ([Guid]::NewGuid()) -Thumbprint $cert.Thumbprint

$appPoolName = 'ExampleAppPool'
Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
Install-IisWebsite -Path $websitePath -Name 'example1.get-carbon.org' `
                   -Bindings ('http/*:80','https/*:443') -AppPoolName $appPoolName

Set-DotNetConnectionString -Name 'example1DB' `
                           -Value 'Data Source=db.example1.get-carbon.org; Initial Catalog=example1DB; Integrated Security=SSPI;' `
                           -Framework64 `
                           -Clr4


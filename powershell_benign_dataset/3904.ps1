














function Test-CertificateCrudOperations
{
    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext
    $thumbprintAlgorithm = "sha1"

    $localDir = ($pwd).Path 

    $certPathVs = $localDir + "/Resources/BatchTestCert01.cer"
    
    
    $x509cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $certPathVs

    
    $x509cert | New-AzBatchCertificate -BatchContext $context

    
    $addedCert = Get-AzBatchCertificate $thumbprintAlgorithm $x509cert.Thumbprint -BatchContext $context
    Assert-AreEqual $x509cert.Thumbprint $addedCert.Thumbprint
    Assert-AreEqual $thumbprintAlgorithm $addedCert.ThumbprintAlgorithm

    
    $addedCert | Remove-AzBatchCertificate -BatchContext $context

    
    $allCerts = Get-AzBatchCertificate -BatchContext $context
    foreach ($c in $allCerts)
    {
        Assert-True { ($c.Thumbprint -ne $x509cert.Thumbprint) -or ($c.State.ToString().ToLower() -eq 'deleting') }
    }
}


function Test-TestCancelCertificateDelete
{
    param([string]$thumbprintAlgorithm, [string]$thumbprint)

    $context = New-Object Microsoft.Azure.Commands.Batch.Test.ScenarioTests.ScenarioTestContext

    
    $cert = Get-AzBatchCertificate $thumbprintAlgorithm $thumbprint -BatchContext $context
    Assert-AreEqual 'deletefailed' $cert.State.ToString().ToLower()

    Get-AzBatchCertificate $thumbprintAlgorithm $thumbprint -BatchContext $context | Stop-AzBatchCertificateDeletion -BatchContext $context

    
    $filter = "state eq 'active'"
    $cert = Get-AzBatchCertificate -Filter $filter -BatchContext $context
    
    Assert-AreEqual $thumbprint $cert.Thumbprint.ToLowerInvariant()
}
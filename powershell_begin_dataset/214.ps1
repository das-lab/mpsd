Function Remove-HashTableEmptyValue
{

    [CmdletBinding()]
    PARAM([System.Collections.Hashtable]$HashTable)

    $HashTable.GetEnumerator().name |
        ForEach-Object -Process {
            if($HashTable[$_] -eq "" -or $HashTable[$_] -eq $null)
            {
                Write-Verbose -Message "[Remove-HashTableEmptyValue][PROCESS] - Property: $_ removing..."
                [void]$HashTable.Remove($_)
                Write-Verbose -Message "[Remove-HashTableEmptyValue][PROCESS] - Property: $_ removed"
            }
        }
}
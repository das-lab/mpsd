Function Get-HashTableEmptyValue
{

    PARAM([System.Collections.Hashtable]$HashTable)

    $HashTable.GetEnumerator().name |
        ForEach-Object -Process {
            if($HashTable[$_] -eq "" -or $HashTable[$_] -eq $null)
            {
                Write-Output $_
            }
        }
}
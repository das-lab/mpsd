Function Get-HashTableNotEmptyOrNullValue
{

    PARAM([System.Collections.Hashtable]$HashTable)

    $HashTable.GetEnumerator().name |
        ForEach-Object -Process {
            if($HashTable[$_] -ne "")
            {
                Write-Output $_
            }
        }
}

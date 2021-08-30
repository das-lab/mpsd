function New-TestDataSource() {
    $dataSource = New-Object -TypeName PSObject
    $dataSourceName = 'SimpleDataSource' + [System.DateTime]::Now.Ticks

    $dataSource | Add-Member -MemberType NoteProperty -Name Name -Value $dataSourceName
    $dataSource | Add-Member -MemberType NoteProperty -Name ConnectionString -Value 'Data Source=localhost;'
    $dataSource | Add-Member -MemberType NoteProperty -Name Extension -Value 'SQL'
    $dataSource | Add-Member -MemberType NoteProperty -Name CredentialRetrievalType -Value 'None'
    $dataSource | Add-Member -MemberType NoteProperty -Name Path -Value "/$dataSourceName"

    return $dataSource
}

function Test-AccessToEncryptedContent() {
    param(
        [Parameter(Mandatory=$True)]
        [PSObject]$ExpectedDataSource
    )

    $dataSource = Get-RsDataSource -DataSourcePath $ExpectedDataSource.Path
    $dataSource.Extension | Should be $ExpectedDataSource.Extension
    $dataSource.ConnectString | Should be $ExpectedDataSource.ConnectionString
    $dataSource.CredentialRetrieval | Should be $ExpectedDataSource.CredentialRetrievalType
}











































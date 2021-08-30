function New-MockObject {
    

    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [type]$Type
    )

    [System.Runtime.Serialization.Formatterservices]::GetUninitializedObject($Type)

}

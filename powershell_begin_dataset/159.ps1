function New-RandomPassword
{

    PARAM (
        [Int32]$Length = 12,

        [Int32]$NumberOfNonAlphanumericCharacters = 5,

        [Int32]$Count = 1
    )

    BEGIN
    {
        Add-Type -AssemblyName System.web;
    }

    PROCESS
    {
        1..$Count | ForEach-Object {
            [System.Web.Security.Membership]::GeneratePassword($Length, $NumberOfNonAlphanumericCharacters)
        }
    }
}
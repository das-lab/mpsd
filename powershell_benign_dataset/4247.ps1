

Function Get-CreditCardData {

    param (
      [string]$path = $(throw "-path is required";)
    )

    $Excel = New-Object -ComObject Excel.Application

    $REGEX = [regex]"(?im)(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})"
    $REGEX2 = [regex]"^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})$"
    $REGEX3 = [regex]"[456][0-9]{15}","[456][0-9]{3}[-| ][0-9]{4} [-| ][0-9]{4}[-| ][0-9]{4}"

    Get-ChildItem -Rec -Exclude *.exe,*.dll $path -File | % {

        
            
            
            
            
            
        

        if ((Select-String -pattern $REGEX -Path $_.FullName -AllMatches).Matches.Count -gt 5 ) {
            Write-Output "[+] Potential Card data found:" $_.FullName -ForegroundColor green
            return
        }

    }
    
}










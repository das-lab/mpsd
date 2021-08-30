

    $Day = DATA {

ConvertFrom-StringData @'
    messageDate = Today is
    d0 = Sunday
    d1 = Monday
    d2 = Tuesday
    d3 = Wednesday
    d4 = Thursday
    d5 = Friday
    d6 = Saturday
'@
}

Import-LocalizedData -BindingVariable Day


$a = $Day.d0, $Day.d1, $Day.d2, $Day.d3, $Day.d4, $Day.d5, $Day.d6

        
        
        

        "{0} {1}" -f $Day.messageDate, $a[(get-date -uformat %u)] | Out-Host


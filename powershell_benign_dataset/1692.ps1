



filter notnull {
    $props = @()
    $obj = $_
    $obj | gm -m *property | % { if ( $obj.$($_.name) ) {$props += $_.name} }
    $obj | select $props
}

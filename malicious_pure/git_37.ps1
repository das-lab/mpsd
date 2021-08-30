function Find-TrustedDocuments
{

    $BASE_EXCEL_REG_LOCATIONS = "HKCU:\Software\Microsoft\Office\11.0\Excel\Security", "HKCU:\Software\Microsoft\Office\12.0\Excel\Security", "HKCU:\Software\Microsoft\Office\14.0\Excel\Security", "HKCU:\Software\Microsoft\Office\15.0\Excel\Security" 

    $verified_excel_base_reg_locations = @()
    $trusted_excel_documents = @()

    
    foreach ($location in $BASE_EXCEL_REG_LOCATIONS){
        $valid_path = Test-Path $location
        if ($valid_path -eq $True){
            $verified_excel_base_reg_locations += $location
        }
    }
    if ($verified_excel_base_reg_locations.length -eq 0){
        Write-Output "[*] No trusted document locations found"
    }
    else {
        Write-Output "[+] Trusted Document Locations for Excel"
        
        foreach ($base_excel_reg_location in $verified_excel_base_reg_locations){
            $trusted_location_root = $base_excel_reg_location + "\Trusted Locations"
            $all_trusted_locations = (Get-ChildItem $trusted_location_root) | Select Name
            foreach ($loc in $all_trusted_locations){
                $complete_reg_path = $trusted_location_root + "\" + ($loc.Name | Split-Path -leaf)
                $location_props = Get-ItemProperty $complete_reg_path
                $path = $location_props.Path
                Write-Output $path
            }
        }
    }
    
    foreach ($valid_location in $verified_excel_base_reg_locations){
        $valid_location = $valid_location + "\Trusted Documents"
        if ((Test-Path $valid_location) -eq $True){
            $trusted_document_property = Get-ChildItem $valid_location | select Property
            $trusted_document = [System.Environment]::ExpandEnvironmentVariables($trusted_document_property.property)
            $trusted_excel_documents += $trusted_document
        }
    }
    if ($trusted_excel_documents.length -eq 0){
        Write-Output "`n[*] No trusted documents found"
    }
    else{
        Write-Output "`n[+] Trusted documents:"
        foreach ($doc in $trusted_excel_documents){
            Write-Output $doc"`n"
    }
    }
    Write-Output "`n"
}
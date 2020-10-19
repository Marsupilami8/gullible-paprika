<#

.SYNOPSIS
    Script to conduct a hash verification of digital evidence images using AccessData's legacy FTK Imager Command Line Interface tool.

.DESCRIPTION
    The VerifyImageHash.ps1 Powershell script is used to conduct a recursive MD5 and SHA1 hash verification of E01/S01 forensic images in a drive folder using AccessData's 
    legacy FTK Imager Command Line Interface tool. The script uses background jobs to run multiple hash verifications at a time. The output is a text file containing the 
    notes from each of the forensic image acquisitions and the results of the computed MD5 and SHA1 hash verifications.

.EXAMPLE
    PS C:\\> VerifyImageHash.ps1
    The script is placed in the uppermost root folder of all the E01 and S01 images.

.INPUTS
    None. You cannot pipe objects to VerifyImageHash.ps1. Folders containing E01 or S01 formatted digital forensic images are the input objects.
     
.OUTPUTS
    Date time stamped log text file of aggregated output of the hash verifications from AccessData FTK Imager in the format of "yyyymmddhhmmss-ImageHashVerification.txt". 
    Filename will be located in the root folder from where the script was run.

.LINK
    https://accessdata.com/product-download/windows-32bit-3-1-1

.NOTES
    The FTK Imager command line tool (version 3.1.1) must be downloaded from Accessdata and installed to a folder of your choice (See link). The path to the "ftkimager.exe" executable 
    placed in the PATH environment variable; otherwise, its explicit path must be added in this script. The FTK Imager tool does not work to verify images in AD1, L01, DD, or any 
    other formats. The number of background jobs is limited to 20. When a max is acchieved, no other jobs are started until a job is freed, after a waiting period. No stress tests have done. 
    Use at your own risk. The script outputs the ftkimager.exe command line stderr messages to stdout, which will be caputed in the log text file.

.TODO
    Add command line arguments such that a path can be added for the root folder or volume that contains the forensic images.

.AUTHOR
    Marsupilami8

.DATE
    2020-10-18

.VERSION
    1.9

#>

# Create the construct for the hash verification output containing acquisition notes and computed hash verifications
$script =  {

   Param($file)

    if(Test-Path $file){

        $header = (Get-Date -Format s)  + "`r`n$file`r`n"
        $imageInfo = cmd /c ftkimager.exe $file --print-info '2>&1' | Out-String # Cleaner output with line breaks
        $hashVerification = cmd /c ftkimager.exe $file --verify --quiet '2>&1' | Out-String
        $footer = "`r`n" + "---------------------------------------------------------" + "`r`n"  
        $results = $header + $imageInfo + $hashVerification + $footer 

    }
    else {

        $results = "Error: $file Not Found."
        exit
    }
   
   Write-Output -InputObject $results
   }

$LogFile = (Get-Date -Format "yyyyMMddTHHmmss")  + "-ImageHashVerification.txt"

# Find all forensic image types from where the script is located.  
$forensicImages = Get-ChildItem -Recurse -Include *.e01,  *.e01x, *.s01, *.ad1, *.l01, *.l01x, *.dd, *.001, *.zip

if (!$forensicImages) {

   Write-Host "No forensic image files were found in the folder to verify."
   (Get-Date -Format s)  + "`r`nNo forensic image files were found in the root folder to verify." | `
    Out-File -Append -FilePath $LogFile -Encoding ascii

   exit
}

$SupportedForensicImages = New-Object -TypeName "System.Collections.ArrayList"
$NonSupportedForensicImages = New-Object -TypeName "System.Collections.ArrayList"

# Identify forensic image types supported by FTK Imager, such as E01 and S01 format, to run verification script.
foreach($image in $forensicImages){

 if ($image.Extension -IN ".e01x", ".ad1", ".l01", ".l01x", ".dd", ".001", ".zip") {

    $NonSupportedForensicImages.Add($image) | Out-Null # prevents index from echoing to console

    $NonSupportMsg =  (Get-Date -Format s) + "`r`n$image`r`nThe verification of this image type is unsupported. Please verify using an alternate method.`r`n" `
        + "---------------------------------------------------------" + "`r`n" 

    Out-File -Append -FilePath $LogFile -InputObject $NonSupportMsg -Encoding ascii

 } elseif ($image.Extension -IN ".s01", ".e01"){

    $SupportedForensicImages.Add($image) | Out-Null 

 } else {

    continue
 }
}

# Update to console on images being verified
Write-Host "`r`nThe following images are unsupported and cannot be verified with this tool: ` 
    `r`n$($NonSupportedForensicImages -join "`r`n")`r`n"
Write-Host "`r`nVerifying the following images: `
    `r`n$($SupportedForensicImages -join "`r`n")`r`n"

# Limit to no greater than 20 background jobs and check again in 3 min for freed jobs 
foreach($image in $SupportedForensicImages){

   while ((Get-Job -State Running).Count -ge 20) {

      Start-Sleep -Seconds 180;
   }

   Start-Job -Scriptblock $script -ArgumentList $image.FullName -Name (Split-Path $image -Leaf)
}

# Push out background job results to logged time/date stamped file.
Get-Job | Wait-Job | Receive-Job | Out-File -Append -FilePath $LogFile -Encoding ascii

Write-Host "`r`nImage verification completed. See the $LogFile file for results."

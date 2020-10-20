﻿<#

.SYNOPSIS
    Script to conduct a hash verification of digital evidence images using AccessData's legacy FTK Imager Command Line Interface tool.

.DESCRIPTION
    The VerifyImageHash.ps1 Powershell script is a command line executable wrapper used to conduct a recursive MD5 and SHA1 hash verification of E01/S01 forensic images in a drive folder using 
    AccessData's legacy FTK Imager Command Line Interface tool (version 3.1.1). The script uses background jobs to run multiple hash verifications at a time. The output is a text file 
    containing the notes from each of the forensic image acquisitions and the results of the computed MD5 and SHA1 hash verifications.

.PARAMETER TargetFolder - Volume path to folder containing forensic images.
 
.PARAMETER OutputFolder  - Volume path to folder where verification file log will be generated.

.EXAMPLE
    Copy the the script to the root folder contain all the forensic images. Open a Powershell terminal to the root location in the uppermost root folder of all the E01 and S01 image. 
    This can be done, for example, by typing "powershell" in the folder path bar in an Explorer window. The verification text file output will be generated in the root folder from where 
    the script was run. The default image containers are assumed to be in the same folder as the script.

    PS C:\\> VerifyImageHash.ps1
 
.EXAMPLE
    Open a Powershell terminal. Run the script and provide the target folder's path to the volume and root folder containing the forensic images. The verification text file output will be 
    generated in the folder from where the script was run.

    PS C:\\> VerifyImageHash.ps1 -TargetFolder "D:\IMAGES\TX1\"

.EXAMPLE
    Open a Powershell terminal. Run the script and provide the target folder's path to the volume and root folder containing the forensic images. Designate the output folder where the verification 
    text file will be generated.

    PS C:\\> VerifyImageHash.ps1 -TargetFolder "D:\IMAGES\TX1\" -OutputFolder "C:\Users\DFIR\Documents\Case 123\Image Verification Logs\"

.EXAMPLE
    Open a Powershell terminal. Run the script and provide the output folder where the verification text file will be generated. The default image containers are assumed to be in the same 
    folder as the script.

    PS C:\\> VerifyImageHash.ps1 -OutputFolder "C:\Users\DFIR\Documents\Case 123\Image Verification Logs\"

.INPUTS
    Folders containing E01 or S01 formatted digital forensic images are the input objects. You cannot pipe objects to VerifyImageHash.ps1.
     
.OUTPUTS
    Date and time stamped log text file of aggregated output of the hash verifications from AccessData FTK Imager (version 3.1.1) in the format of "yyyymmddhhmmss-ImageHashVerification.txt". 
    File will be located in the root folder from where the script was run. Note that this script can be append the hash verification message confirmation to the .TXT file originally generated by any FTK Imager versios used to image a drive or volume.
    This .TXT file is located in the folder where the E01 segments are found and has the same naming convention as the E01 filename. The script will not create this .TXT file if it was not there to begin with, rather the results of the verification will solely
    be available in the generated "yyyymmddhhmmss-ImageHashVerification.txt" file.

.LINK
    https://accessdata.com/product-download/windows-32bit-3-1-1

.NOTES
    The FTK Imager command line tool (version 3.1.1) must be downloaded from Accessdata and installed to a folder of your choice (See link). The path to the "ftkimager.exe" executable 
    placed in the PATH environment variable; otherwise, its explicit path must be added in this script. The FTK Imager tool does not work to verify images in AD1, L01, DD, or any 
    other formats. The number of background jobs is limited to 20. When a max is acchieved, no other jobs are started until a job is freed, after a timed waiting period. No stress tests 
    have done, use at your own risk. The script outputs the ftkimager.exe command line stderr messages to stdout, which will be captured in the log text file. This does not any impact results.
    
    Author:  Marsupilami8
    Date:    2020-10-20
    Version: 2.0

#>


Param (
    [string]$TargetFolder = ".",
    [string]$OutputFolder = "."
    )

# Test if path provided at command line argument is a folder
If(!(Test-Path $TargetFolder -PathType Container)){

    Write-Host "$TargetFolder is invalid. Please provide the path to the root folder of the forensic images."
    Exit
}

# Test and construct path/name of log file
If(!(Test-Path $OutputFolder -PathType Container)){

    Write-Host "$OutputFolder is invalid. Please provide path to a folder."
    Exit

} Else {

$LogFile = $OutputFolder +"\" + (Get-Date -Format "yyyyMMddTHHmmss")  + "-ImageHashVerification.txt"

}

# Create the construct for the hash verification output containing acquisition notes and computed hash verifications
$Script =  { 

   Param($File)

    If(Test-Path $File){

        $Header = (Get-Date -Format s)  + "`r`n$file`r`n"
        $ImageInfo = cmd /c ftkimager.exe $file --print-info '2>&1' | Out-String # Cleaner output with line breaks
        $HashVerification = cmd /c ftkimager.exe $file --verify --quiet '2>&1' | Out-String
        $Footer = "`r`n" + "---------------------------------------------------------" + "`r`n"  
        $Results = $header + $ImageInfo + $HashVerification + $Footer 

    }
    Else {

        $Results = "Error: $file Not Found."
        Exit
    }
   
   Write-Output -InputObject $Results
   }

# Find all forensic image types from where the script is located.  
$forensicImages = Get-ChildItem $TargetFolder -Recurse -Include *.e01,  *.e01x, *.s01, *.ad1, *.l01, *.l01x, *.dd, *.001, *.zip

If (!$forensicImages) {

   Write-Host "No forensic image files were found in the folder to verify."
   (Get-Date -Format s)  + "`r`nNo forensic image files were found in the root folder to verify." | `
    Out-File -Append -FilePath $LogFile -Encoding ascii

   Exit
}

$SupportedForensicImages = New-Object -TypeName "System.Collections.ArrayList"
$NonSupportedForensicImages = New-Object -TypeName "System.Collections.ArrayList"

# Identify forensic image types supported by FTK Imager, such as E01 and S01 format, to run verification script.
foreach($Image in $ForensicImages){

 if ($Image.Extension -IN ".e01x", ".ad1", ".l01", ".l01x", ".dd", ".001", ".zip") {

    $NonSupportedForensicImages.Add($Image) | Out-Null # prevents index from echoing to console

    $NonSupportMsg =  (Get-Date -Format s) + "`r`n$Image`r`nThe verification of this image type is unsupported. Please verify using an alternate method.`r`n" `
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
    `r`n$($NonSupportedForensicImages -join "`r`n")`r`n" -ForegroundColor Red

Write-Host "`r`nVerifying the following images: `
    `r`n$($SupportedForensicImages -join "`r`n")`r`n" -ForegroundColor Green

# Limit to no greater than 20 background jobs and check again in 3 min for freed jobs 
foreach($image in $SupportedForensicImages){

   while ((Get-Job -State Running).Count -ge 20) {

      Start-Sleep -Seconds 180;
   }

   Start-Job -Scriptblock $script -ArgumentList $image.FullName -Name (Split-Path $image -Leaf)
}

# Push out background job results to logged time/date stamped file.
Get-Job | Wait-Job | Receive-Job | Out-File -Append -FilePath $LogFile -Encoding ascii

Write-Host "`r`nImage hash verification(s) completed. See the $LogFile file for results." -ForegroundColor Magenta

<#

.SYNOPSIS
    Script to conduct a hash verification of digital evidence images using AccessData's legacy FTK Imager Command Line Interface tool.

.DESCRIPTION
    The VerifyImageHash.ps1 Powershell script is used to conduct a recursive MD5 and SHA1 hash verification of E01/S01 images in a drive folder using AccessData's legacy 
    FTK Imager Command Line Interface tool. The script uses threaded background jobs to run multiple hash verifications at a time. The output is a text file containing the 
    notes from each of the forensic image acquisition and the results of the computed MD5 and SHA1 hash verifications.

.EXAMPLE
    PS C:\\> VerifyImageHash.ps1
    The script is placed in the root folder of all the E01 and S01 images.

.INPUTS
    None. You cannot pipe objects to VerifyImageHash.ps1. Folders containing E01 or S01 formatted digital forensic images are the input objects.
     
.OUTPUTS
    Date Time stamped text file of aggregated output of the hash verifications from AccessData FTK Imager in the format of "yyyymmddhhmmss-ImageHashVerification.txt". 
    Filename will be located in the root folder from where the script was run.

.LINK
    https://accessdata.com/product-download/windows-32bit-3-1-1

.NOTES
    The FTK Imager command line tool must be placed in the PATH environment variable; otherwise, its explicit path must be listed in the script. The FTK Imager 
    tool does not work with AD1, L01, DD, or any other formats. If a PS command line prompt is available, you can run the Get-Job command to identify any outstanding jobs.
    The script outputs some stderr messages that can be piped to 2>1 | $null for cleaner output when the Powershell is run in an IDE.

.AUTHOR
    Marsupilami8

.DATE
    2020-08-04

.VERSION
    1.0

#>

# Create the construct for the hash verification output containing acquisition notes and computed hash verifications
$script =  {
   Param($fileName)
   if(Test-Path $fileName){
    $header = "$fileName" + "`r`n"
    $imageInfo = ftkimager.exe $fileName --print-info 
    $hashVerification = ftkimager.exe $fileName --verify --quiet
    $footer = "`r`n" + "_____________________________________" + "`r`n" 
    $results = $header + $imageInfo + $hashVerification + $footer
   }
   Else {
      $results = "Error: $fileName Not Found."
   }
   Write-Output -InputObject $results
   }


# Find all forensic images from where the script is located that are E01 or S01 format. 
$forensicImages = Get-ChildItem -Recurse -Include *.e01, *.s01
$NonSupportedForensicImages = Get-ChildItem -Recurse -Include *.ad1, *.l01, *.zip, *.dd, *.001

# Limit to no greater than 12 background jobs and wait until done
foreach($image in $forensicImages.FullName){
   while ((Get-Job -State Running).Count -ge 12) {
      Start-Sleep -Seconds 120;
   }
   Start-Job -Scriptblock $script -ArgumentList $image -Name (Split-Path $image -Leaf)
}

# Push out background job results to a file.
Get-Job | Wait-Job | Receive-Job | Out-File -Append -FilePath ((Get-Date -Format "yyyyMMddTHHmmss")  + '-ImageHashVerification.txt') -Encoding ASCII

#TODO Add code to find non-supported image formats and

<# if (Get-ChildItem -Recurse -Include *.ad1, *.l01, *.zip, *.dd, *.001) {}
Out-File $file 

#>

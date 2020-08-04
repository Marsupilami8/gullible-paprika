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
      $results = "$fileName Not Found"
   }
   Write-Output -InputObject $results
   }

$forensicImages = Get-ChildItem -Recurse -Include *.e01, *.s01

foreach($image in $forensicImages.FullName){
   while ((Get-Job -State Running).Count -ge 10) {
      Start-Sleep -Seconds 60;
   }
   Start-Job -Scriptblock $script -ArgumentList $image
}
Get-Job | Wait-Job | Receive-Job | Out-File -Append -FilePath ((Get-Date -Format "yyyymmddhhmmss")  + '-ImageHashVerification.txt') -Encoding ASCII
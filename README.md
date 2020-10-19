# gullible-paprika
 Powershell script wrapper for the command line executable tool for AccessData's FTK Imager, used to conduct hash verifications of 
 E01/S01 images in a volume folder.
 
 The script is used to conduct a recursive MD5 and SHA1 hash verification of E01/S01 forensic images in a drive folder using 
 AccessData's legacy FTK Imager Command Line Interface tool (version 3.1.1). The script uses background jobs to run multiple hash verifications 
 at a time. The output is a single text file containing the notes from each of the forensic image acquisitions and the results of the computed MD5 
 and SHA1 hash verifications.

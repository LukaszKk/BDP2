#TODO: update description
#===================================#
#            Changelog              #
#                                   #
# The purpose of this script is to                                #
#                                   #
# Author: 290915                    #
# Date: 01/13/2021                  #
#                                   #
#===================================#

# imports
$workingDir = $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem
Import-Module "$($workingDir)\module.ps1"

# parameters
# TODO: make it params
$uri = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"

$zipFileName = $uri.Substring($uri.LastIndexOf('/') + 1)
$zipFile = "$($workingDir)\$($zipFileName)"
$zipPassword = "bdp2agh"
$7ZipPath = "C:\Program Files\7-Zip\7z.exe"

$TIMESTAMP =  Get-Date -format "MM-dd-yyyy"

$faultyFile = "InternetSales_new.bad_$($TIMESTAMP)"
RemoveFile $faultyFile
CreateFile $faultyFile

$logfile = "$($workingDir)\logs.log"
RemoveFile $logFile
CreateFile $logFile

$tmp = "$($workingDir)\tmp.txt"
RemoveFile $tmp
CreateFile $tmp

$fileNameWithoutExt = $zipFileName.Substring(0, $zipFileName.LastIndexOf('.'))
$file = "$($workingDir)\$($fileNameWithoutExt).txt" # C:/.../InternetSales_new.txt
$fileOld = "$($workingDir)\InternetSales_old.txt"

# download file
Invoke-WebRequest -Uri $uri -OutFile $zipFile

# unzip
Unzip $zipFile $workingDir $zipPassword

# check if file exists after unzip
CheckFileExists $file

# discard empty lines
DiscardEmptyLines $file

# only unique lines and
# only rows with the same columns count as in the header
# OrderQuantity max value 100
# compare content with old file
# SecretCode is empty
# CustomerName contains ','
FilterFile $file $fileOld $faultyFile $tmp
CopyContent $tmp $file
ClearContent $tmp

# divide into 2 columns
DivideColumn $file $tmp
CopyContent $tmp $file
ClearContent $tmp

Write-Host 1
LogMessage "Exit"

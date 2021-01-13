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

$Logfile = "$($workingDir)\logs.log"
RemoveFile $LogFile

$tmp = "$($workingDir)\tmp.txt"
RemoveFile $tmp

$fileNameWithoutExt = $zipFileName.Substring(0, $zipFileName.LastIndexOf('.'))
$file = "$($workingDir)\$($fileNameWithoutExt).txt" # C:/.../InternetSales_new.txt

# download file
Invoke-WebRequest -Uri $uri -OutFile $zipFile

# unzip
Unzip $7ZipPath $zipFile $workingDir $zipPassword

# check if file exists after unzip
CheckFileExists $file

# discard empty lines
DiscardEmptyLines $file

# leave only unique lines
UniqueLinesFilter $file $faultyFile $tmp
CopyContent $tmp $file
RemoveFile $tmp

# rows with proper columns count
ColumnCountFilter $file $faultyFile $tmp
CopyContent $tmp $file
RemoveFile $tmp

# 


Write-Host $columnsCount
LogMessage "Exit"

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
$fileName = "$($fileNameWithoutExt).txt"
$file = "$($workingDir)\$($fileName)" # C:/.../InternetSales_new.txt
$fileOld = "$($workingDir)\InternetSales_old.txt"

# download file
Invoke-WebRequest -Uri $uri -OutFile $zipFile

# unzip
Unzip $zipFile $workingDir $zipPassword

# check if file exists after unzip
CheckFileExists $file
$inputLinesCount = GetFileLinesCount $file

# discard empty lines
DiscardEmptyLines $file

# only unique lines and
# only rows with the same columns count as in the header
# OrderQuantity max value 100
# compare content with old file
# SecretCode is empty
# CustomerName contains ','
$duplicatesCount = FilterFile $file $fileOld $faultyFile $tmp
CopyContent $tmp $file
ClearContent $tmp

# divide into 2 columns
DivideColumn $file $tmp
CopyContent $tmp $file
RemoveFile $tmp

# create table CUSTOMERS_290915
$myconnection = CreateConnection
CreateTable $myconnection

# insert values
$dbLoadedCount = InsertValues $myconnection $file $tmp

# count lines
$filteredLinesCount = GetFileLinesCount $file
$rejectedLinesCount = GetFileLinesCount $faultyFile

# move input file
$processedDir = "$($workingDir)\PROCESSED"
$movedFile = "$processedDir\$($TIMESTAMP)_$($fileName)"
CreateDir $processedDir
RemoveFile $movedFile
MoveFile $file $movedFile

# send email
$subject = "CUSTOMERS LOAD - $($TIMESTAMP)"
$body = @"
    Input file lines count: $($inputLinesCount)
    File lines count after filtration: $($filteredLinesCount)
    Duplicates in input file: $($duplicatesCount)
    Rejected lines count: $($rejectedLinesCount)
    Loaded to db count: $($dbLoadedCount)
"@
LogMessage "Message subject: $subject"
LogMessage @"
Message content:
$($body)
"@
SendEmail $subject $body

# update SecretCode
$randomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
UpdateColumnValue $myconnection "SecretCode" $randomString

# export table to csv
$csvFile = "$($workingDir)\table.csv"
RemoveFile $csvFile
ExportToCSV $myconnection $csvFile

# compress file
$csvFileZip = "$($workingDir)\table.zip"
RemoveFile $csvFileZip
CompressFile $csvFile $csvFileZip

# send email with attachment
$csvLinesCount = GetFileLinesCount $csvFile
$creationTime = GetCreationTime $csvFileZip
$subject = "Archived file - $($TIMESTAMP)"
$body = @"
    Creation time: $($creationTime)
    Lines Count: $($csvLinesCount)
"@
LogMessage "Message subject: $subject"
LogMessage @"
Message content:
$($body)
"@
SendEmail $subject $body $csvFileZip

# 

# exit
LogMessage "Exit"

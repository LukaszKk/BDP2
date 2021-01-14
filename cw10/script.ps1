#TODO: update description
#===================================#
#            Changelog              #
#                                   #
# The purpose of this script is to                                #
#                                   #
# Author: 290915                    #
# Created: 01/13/2021               #
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

$processedDir = "$($workingDir)\PROCESSED"
CreateDir $processedDir

$currentScriptName = $MyInvocation.MyCommand.Name

$logfile = "$($processedDir)\$($currentScriptName.Substring(0, $currentScriptName.LastIndexOf('.')))_$($TIMESTAMP).log"
RemoveFile $logFile
CreateFile $logFile

$tmp = "$($workingDir)\tmp.txt"
RemoveFile $tmp
CreateFile $tmp

$fileNameWithoutExt = $zipFileName.Substring(0, $zipFileName.LastIndexOf('.'))
$fileName = "$($fileNameWithoutExt).txt"
$file = "$($workingDir)\$($fileName)" # C:/.../InternetSales_new.txt
$fileOld = "$($workingDir)\InternetSales_old.txt"

$step = "Downloading"
Write-Host $step
try {
    # download file
    Invoke-WebRequest -Uri $uri -OutFile $zipFile
} catch {
    LogMessage "$($step) - FAILED" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Unzipping"
Write-Host $step
try {
    # unzip
    Unzip $zipFile $workingDir $zipPassword

    # check if file exists after unzip
    CheckFileExists $file
    $inputLinesCount = GetFileLinesCount $file
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "File filtration"
Write-Host $step
try {
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
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Table creation"
Write-Host $step
try {
    # create table CUSTOMERS_290915
    $myconnection = CreateConnection
    CreateTable $myconnection
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Inserting values"
Write-Host $step
try {
    # insert values
    $dbLoadedCount = InsertValues $myconnection $file $tmp
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

# count lines
$filteredLinesCount = GetFileLinesCount $file
$rejectedLinesCount = GetFileLinesCount $faultyFile

$step = "File moving and renaming"
Write-Host $step
try {
    # move input file
    $movedFile = "$processedDir\$($TIMESTAMP)_$($fileName)"
    RemoveFile $movedFile
    MoveFile $file $movedFile
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Sending email about customers load"
Write-Host $step
try {
    # send email
    $subject = "CUSTOMERS LOAD - $($TIMESTAMP)"
    $body = "
        Input file lines count: $($inputLinesCount)
        File lines count after filtration: $($filteredLinesCount)
        Duplicates in input file: $($duplicatesCount)
        Rejected lines count: $($rejectedLinesCount)
        Loaded to db count: $($dbLoadedCount)
    "
    LogMessage "Message subject: $subject"
    LogMessage "Message content:
    $($body)"
    SendEmail $subject $body
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    # ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Updating SecretCode column value"
Write-Host $step
try {
    # update SecretCode
    $randomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
    UpdateColumnValue $myconnection "SecretCode" $randomString
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Exporting table to CSV"
Write-Host $step
try {
    # export table to csv
    $csvFile = "$($workingDir)\table.csv"
    RemoveFile $csvFile
    ExportToCSV $myconnection $csvFile
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Compressing file"
Write-Host $step
try {
    # compress file
    $csvFileZip = "$($workingDir)\table.zip"
    RemoveFile $csvFileZip
    CompressFile $csvFile $csvFileZip
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    ExitWithError
}
LogMessage "$($step) - SUCCESS"

$step = "Sending email with compressed file as attachment"
Write-Host $step
try {
    # send email with attachment
    $csvLinesCount = GetFileLinesCount $csvFile
    $creationTime = GetCreationTime $csvFileZip
    $subject = "Archived file - $($TIMESTAMP)"
    $body = "
        Creation time: $($creationTime)
        Lines Count: $($csvLinesCount)
    "
    LogMessage "Message subject: $subject"
    LogMessage "Message content:
    $($body)"
    SendEmail $subject $body $csvFileZip
} catch {
    LogMessage "$($step) - Failed" "ERROR"
    # ExitWithError
}
LogMessage "$($step) - SUCCESS"

# exit
LogMessage "Shuting down"

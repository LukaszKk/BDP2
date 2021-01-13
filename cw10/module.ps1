#===================================#
#            Changelog              #
#                                   #
#                                   #
# Author: 290915                    #
# Date: 01/13/2021                  #
#                                   #
#===================================#


Function LogMessage
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}


Function ExitWithError
{
    LogMessage "Failure"
    # Write-Error "Failure"
    Exit
}


Function RemoveFile
{
    Param ([string]$file)

    if (Test-Path $file) 
    {
        Remove-Item $file
    }
}


Function CheckFileExists
{
    Param ([string]$file)

    if (-Not (Test-Path $file))
    {
        LogMessage "File has not been found: $($file)"
        Write-Warning "File has not been found: $($file)"
        ExitWithError
    }
}


Function CopyContent
{
    Param ([string]$inFile, [string]$outFile)

    Get-Content $inFile | Set-Content $outFile
}


Function Unzip
{
    Param ([string]$7ZipPath, [string]$file, [string]$output, [string]$password)

    $unzipCommand = "& '$7ZipPath' e -o$output -y -tzip -p$password $file"
    iex $unzipCommand 2>&1 | Out-Null
}


Function DiscardEmptyLines
{
    Param ([string]$file)

    (Get-Content $file) | Where-Object{$_.length -gt 0} | Set-Content $file
}


Function UniqueLinesFilter
{
    Param ([string]$inFile, [string]$faultyFile, [string]$outFile)

    $set = @{}
    Get-Content $inFile | %{
        if (!$set.Contains($_)) {
            $set.Add($_, $null)
            $_
        } else {
            Add-content $faultyFile -value $_
        }
    } | Set-Content $outFile
}


Function ColumnCountFilter 
{
    Param ([string]$inFile, [string]$faultyFile, [string]$outFile)


    $columnsCount = (Get-Content $inFile | Select-Object -First 1).Split("|").length
    Get-Content $inFile | %{
        $columnsCountInLine = $_.Split("|").length
        if ($columnsCount -eq $columnsCountInLine) {
            $_
        } else {
            Add-content $faultyFile -value $_
        }
    } | Set-Content $outFile
}
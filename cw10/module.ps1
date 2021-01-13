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

   Add-content $logfile -value $logstring
}


Function ExitWithError
{
    LogMessage "Failure"
    # Write-Error "Failure"
    Exit
}


Function CreateFile
{
    Param ([string]$file)

    if (-Not (Test-Path $file)) 
    {
        New-Item -Path $file -ItemType file 
    }
}


Function ClearContent
{
    Param ([string]$file)

    if (Test-Path $file) 
    {
        Clear-Content -Path $file
    }
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

    Copy-Item $inFile $outFile
}


Function Unzip
{
    Param ([string]$file, [string]$output, [string]$password)

    $unzipCommand = "& '$7ZipPath' e -o$output -y -tzip -p$password $file"
    iex $unzipCommand 2>&1 | Out-Null
}


Function DiscardEmptyLines
{
    Param ([string]$file)

    (Get-Content $file) | Where-Object{$_.length -gt 0} | Set-Content $file
}


Function FilterFile
{
    # Filters: only unique lines, only rows with the same columns count as in the header, max value of the specified column

    Param ([string]$inFile, [string]$oldFile, [string]$faultyFile, [string]$outFile)

    $separator = "|"
    $orderColumnName = "OrderQuantity"
    $maxValue = 100
    $secretColumnName = "SecretCode"
    $customerColumnName = "Customer_Name"

    $set = @{}

    $header = Get-Content $inFile | Select-Object -First 1
    $columns = $header.Split($separator)
    $columnsCount = $columns.length
    $orderIndex = $columns.IndexOf($orderColumnName)
    $secretIndex = $columns.IndexOf($secretColumnName)
    $customerIndex = $columns.IndexOf($customerColumnName)

    $oldContent = Get-Content $oldFile

    Get-Content $inFile | %{
        $columnsInLine = $_.Split($separator)
        $columnsCountInLine = $columnsInLine.length
        $orderColumnValue = $columnsInLine[$orderIndex]
        $secretColumnValue = $columnsInLine[$secretIndex]
        $customerColumnValue = $columnsInLine[$customerIndex]

        if (($header -eq $_) -Or (                                          # check if column is header
            !$set.Contains($_) -And                                         # check duplicate
            $columnsCount -eq $columnsCountInLine -And                      # check if columns count is ok
            $orderColumnValue -le $maxValue -And                            # check if value in column is less then maxValue
            !$oldContent.Contains($_) -And                                  # check if old file contains this line
            $secretColumnValue.length -eq 0 -And                            # check if SecretCode is empty
            $customerColumnValue.Contains(",")                              # check if CustomerName contains ',' 
            )) {

            $set.Add($_, $null)
            $_
        } else {
            $line = $_
            if ($columnsCountInLine -ge ($secretIndex+1)) {                    # remove secret value
                [System.Collections.ArrayList]$arrayList = $columnsInLine
                $arrayList.RemoveAt($secretIndex)                              # remove secret column
                $line = $arrayList -join $separator                            # join using separator
                $line = "$($line)$($separator)"                                # add one separator to the end because one column was deleted
            }
            Add-content $faultyFile -value $line
        }
    } | Set-Content $outFile
}


Function DivideColumn
{
    Param ([string]$inFile, [string]$outFile)

    $separator = "|"
    $customerColumnName = "Customer_Name"
    $customerSeparator = ","

    $header = Get-Content $inFile | Select-Object -First 1
    $isHeader = $true
    $columns = $header.Split($separator)
    $columnsCount = $columns.length
    $customerIndex = $columns.IndexOf($customerColumnName)

    Get-Content $inFile | %{
        $columnsInLine = $_.Split($separator)
        $customerColumnValue = $columnsInLine[$customerIndex].Split($customerSeparator)
        if ($isHeader) {
            $isHeader = $false
            $surname = "LAST_NAME"
            $name = "FIRST_NAME"
        } else {
            $surname = $customerColumnValue[0] -replace '["]','' 
            $name = $customerColumnValue[1] -replace '["]',''
        }
        [System.Collections.ArrayList]$arrayListOfColumns = $columnsInLine
        $arrayListOfColumns.RemoveAt($customerIndex)
        $arrayListOfColumns.Insert($customerIndex, $name)
        $arrayListOfColumns.Insert($customerIndex+1, $surname)
        $line = $arrayListOfColumns -join $separator
        $line
    } | Set-Content $outFile
}
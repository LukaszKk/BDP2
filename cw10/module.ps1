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
    Param ([string]$logstring, [string]$level="")

    $lvl = "INFO"
    if ($level -ne "") {
        $lvl = $level
    }

    $time = Get-Date -format "yyyy-MM-dd hh:mm:ss"
    Add-content $logfile -value "$($time) $($lvl): $($logstring)"
}


Function ExitWithError
{
    LogMessage "Failure"
    Write-Warning "Failure"
    Exit
}


Function CreateFile
{
    Param ([string]$file)

    if (-Not (Test-Path $file)) 
    {
        New-Item -Path $file -ItemType file 2>&1 | Out-Null
    }
}


Function CreateDir
{
    Param ([string]$path)

    if (-Not (Test-Path $path)) 
    {
        New-Item -Path $path -ItemType directory 2>&1 | Out-Null
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


Function MoveFile
{
    Param ([string]$source, [string]$dest)

    if (Test-Path $source) 
    {
        Move-Item -Path $source -Destination $dest
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


Function GetFileLinesCount
{
    Param ([string]$file)

    return (Get-Content $file).length
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
    $duplicatesCount = 0

    Get-Content $inFile | %{
        $columnsInLine = $_.Split($separator)
        $columnsCountInLine = $columnsInLine.length
        $orderColumnValue = $columnsInLine[$orderIndex]
        $secretColumnValue = $columnsInLine[$secretIndex]
        $customerColumnValue = $columnsInLine[$customerIndex]
        
        if ($set.Contains($_)) {                                            # count duplicates. Ugly solution but works
            $duplicatesCount = $duplicatesCount + 1
        }
        
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

    return $duplicatesCount
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


Function CreateConnection
{
    [void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data")

    $dbusername = "root"
    $dbpassword = "Lukasz010!"
    $dbname = "basic"
    [void][System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\MySQL\Connector NET 8.0\Assemblies\v4.5.2\MySql.Data.dll")
    $myconnection = New-Object MySql.Data.MySqlClient.MySqlConnection
    $myconnection.ConnectionString = "server=localhost;user id=$($dbusername);password=$($dbpassword);database=$($dbname);pooling=false"
    return $myconnection
}


Function CreateTable
{
    Param ([MySql.Data.MySqlClient.MySqlConnection]$myconnection)

    $myconnection.Open()

    $mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $mycommand.Connection = $myconnection
    $mycommand.CommandText = "create table if not exists CUSTOMERS_290915 (ProductKey int, CurrencyAlternateKey varchar(3), FIRST_NAME varchar(255), LAST_NAME varchar(255), OrderDateKey varchar(255), OrderQuantity int, UnitPrice float, SecretCode varchar(255));"
    $myreader = $mycommand.ExecuteNonQuery()
    
    $myconnection.Close()
}


Function InsertValues
{
    Param ([MySql.Data.MySqlClient.MySqlConnection]$myconnection, [string]$file)

    $myconnection.Open()

    $mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $mycommand.Connection = $myconnection

    $mytransaction = $myconnection.BeginTransaction()

    $separator = "|"
    $dbSeparator = ","
    $isHeader = $true

    $count = 0

    Get-Content $file | %{
        if ($isHeader -eq $false) {
            $columnsInLine = $_.Split($separator)
            for ($i = 0; $i -lt $columnsInLine.Count ; $i++) {
                $columnsInLine[$i] = $columnsInLine[$i].Replace(",", ".")   # replace all ',' with '.' in values
                if ($columnsInLine[$i].length -eq 0) {                      # replace all '' with 'NULL' in values
                    $columnsInLine[$i] = "NULL"
                }
                $columnsInLine[$i] = "'$($columnsInLine[$i])'"
            }
            $values = $columnsInLine -join $dbSeparator

            $mycommand.CommandText = "insert into CUSTOMERS_290915 values ($($values))"
            $myreader = $mycommand.ExecuteNonQuery()
            $count = $count + 1
        }
        $isHeader = $false
    }

    try {
        $mytransaction.Commit()
    } catch {
        $mytransaction.Rollback()
        $count = 0
        LogMessage "DB error: Nothing inserted" "ERROR"
    } finally {
        $myconnection.Close()
    }

    return $count
}


Function SendEmail
{
    Param ([string]$subject, [string]$body, [string]$attachmentpath="")

    $username = "username"
    $password = "password"
    $message = New-Object Net.Mail.MailMessage
    $message.From = "mail.from@gmail.com"
    $message.To.Add("mail.to@gmail.com")
    $message.Subject = $subject
    $message.Body = $body

    if ($attachmentpath -ne "") {
        $attachment = New-Object Net.Mail.Attachment($attachmentpath);
        $message.Attachments.Add($attachment)
    }

    $smtp = New-Object Net.Mail.SmtpClient("smtp.gmail.com", "587")
    $smtp.EnableSSL = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($username, $password)
    try {
        $smtp.send($message)
    } catch {
        LogMessage "Message send error" "ERROR"
    }
}


Function UpdateColumnValue
{
    Param ([MySql.Data.MySqlClient.MySqlConnection]$myconnection, [string]$column, [string]$value)

    $myconnection.Open()

    $mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $mycommand.Connection = $myconnection

    $mytransaction=$myconnection.BeginTransaction()

    $mycommand.CommandText = "update CUSTOMERS_290915 set $($column) = '$($value)'"
    $myreader = $mycommand.ExecuteNonQuery()

    try {
        $mytransaction.Commit()
    } catch {
        $mytransaction.Rollback()
        LogMessage "DB error: Nothing updated" "ERROR"
    } finally {
        $myconnection.Close()
    }
}


Function ExportToCSV
{
    Param ([MySql.Data.MySqlClient.MySqlConnection]$myconnection, [string]$file)

    $separator = ","

    $myconnection.Open()

    $mycommand = New-Object MySql.Data.MySqlClient.MySqlCommand
    $mycommand.Connection = $myconnection

    $mytransaction=$myconnection.BeginTransaction()

    $file = $file.Replace("\","\\")
    
    $mycommand.CommandText = "
    SELECT 'ProductKey', 'CurrencyAlternateKey', 'FIRST_NAME', 'LAST_NAME', 'OrderDateKey', 'OrderQuantity', 'UnitPrice', 'SecretCode'
    UNION ALL
    SELECT * FROM CUSTOMERS_290915 
    INTO OUTFILE '$($file)'
    FIELDS ENCLOSED BY '' 
    TERMINATED BY '$($separator)' 
    ESCAPED BY '' 
    LINES TERMINATED BY '\r\n';
    "
    $myreader = $mycommand.ExecuteNonQuery()

    try {
        $mytransaction.Commit()
    } catch {
        $mytransaction.Rollback()
        LogMessage "DB error: Nothing exported" "ERROR"
    } finally {
        $myconnection.Close()
    }
}


Function CompressFile
{
    Param([string]$file, [string]$dest)

    Compress-Archive -Path $file -CompressionLevel Fastest -DestinationPath $dest
}


Function GetCreationTime
{
    Param([string]$file)

    return (Get-ChildItem $file).CreationTime
}

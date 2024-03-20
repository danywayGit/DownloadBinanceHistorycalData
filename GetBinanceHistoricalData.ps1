<#
.Synopsis
   Get Binance historical data
.DESCRIPTION
   Get Binance historical data for spot or futur, for multitimeframe , multi pairs
.EXAMPLE
   Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT' -TimeFrame '5m'
.EXAMPLE
   Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT' -TimeFrame '15m'
.EXAMPLE
   Get-BinanceHistoricalData -ContractType 'futures' -BulkSize 'monthly' -Symbol 'ETHUSDT' -TimeFrame '30m' -StartDate (Get-Date "2017-01-01") -EndDate (Get-Date)
#>
function Get-BinanceHistoricalData {
    [CmdletBinding()]
    Param(
        # spot prises or futures prises
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        
        [ValidateSet('spot', 'futures')]
        [string]
        $ContractType='spot',

        # grouped by daily of by monthly
        [ValidateSet('daily', 'monthly')]
        [string]
        $BulkSize='monthly',

        # one symbol
        [string]
        $Symbol='BTCUSDT',

        # one time frame
        [ValidateSet('1mo','1w','3d','1d','12h', '8h', '6h', '4h', '2h', '1h', '30m', '15m', '5m', '3m', '1m', '1s')]
        [string]
        $TimeFrame='5m',

        [datetime]
        $StartDate=(Get-Date "2017-01-01"),

        [datetime]
        $EndDate=(Get-Date)
    )

    # check if start date is before end date
    if ($StartDate -gt $EndDate) {
        throw "Start date must be before end date"
    }

    #check if start date is before 2017-01-01
    if ($StartDate -lt (Get-Date "2017-01-01")) {
        throw "Start date must be after 2017-01-01"
    }

    #check if end date is after today
    if ($EndDate -gt (Get-Date)) {
        throw "End date must be before today"
    }

    #Download all zip files
    $baseUri = 'https://data.binance.vision/data'
    $Uri = "$baseUri/$ContractType/$BulkSize/klines/$Symbol/$TimeFrame"

    $zipFolder = "$Symbol-$TimeFrame-zip-files"
    if (-not (Test-Path $zipFolder)) {
        $null = New-Item -ItemType Directory -Path $zipFolder
    }

    Write-Host "Downloading historical data for symbol $Symbol for contact type $ContractType for the $TimeFrame timeframe from $StartDate to $EndDate, in folder $zipFolder"

    $files = @()
    
    while ($EndDate -ge $startDate) {
        $year = $EndDate.Year
        $month = $EndDate.Month.ToString("D2")
        $zipFileName = "$Symbol-$TimeFrame-$year-$month.zip"
        $EndDate = $EndDate.AddMonths(-1)
        $fileToDownload = "$Uri/$zipFileName"
        $downloadedFilePath = "$zipFolder\$zipFileName"
        $files += @{
            Uri = $fileToDownload
            OutFile = $downloadedFilePath
        }
    }

    $jobs = @()

    foreach ($file in $files) {
        $jobs += Start-ThreadJob -Name $file.OutFile -ScriptBlock {
            $params = $using:file
            $webClient = New-Object System.Net.WebClient
            try{
                #Invoke-WebRequest @params
                $webClient.DownloadFile($params.Uri, $params.OutFile)
            }
            catch {
                $errorMessage = $_.Exception.Message
                $response = $_.Exception.Response
                if ($response -and $response.StatusCode -eq 404) {
                    Write-Host "Warning : $($response.ResponseUri) $($response.StatusCode)." -ForegroundColor Yellow
                }
                else {
                    Write-Host "Warning : $errorMessage" -ForegroundColor Yellow
                    Write-Host "Warning : uri = $($params.Uri)" -ForegroundColor Yellow
                }
            }
        }
    }
        
    Write-Host "Downloads started..."
    Wait-Job -Job $jobs
    
    foreach ($job in $jobs) {
        Receive-Job -Job $job
    }
    
    Write-host "Download complete"

    $csvFolder = "$Symbol-$TimeFrame-csv-files"
    if (-not (Test-Path $csvFolder)) {
        $null = New-Item -ItemType Directory -Path $csvFolder
    }

    Write-host "Unzipping all csv files from all zip files into the folder: $csvFolder"
    Get-ChildItem $zipFolder -Filter *.zip | ForEach-Object { Expand-Archive $_.FullName -DestinationPath $csvFolder -InformationAction Ignore -Force}

    # combine
    $csvCombineFolder = $Symbol
    $csvCombineFileNoHeader = "$Symbol-$TimeFrame-noheader.csv"
    $csvCombineFileNoHeaderFullPath = "$csvCombineFolder\$csvCombineFileNoHeader"
    $csvCombineFile = "$Symbol-$TimeFrame.csv"
    $csvCombineFileFullPath = "$csvCombineFolder\$csvCombineFile"
    if (-not (Test-Path $csvCombineFolder)) {
        $null = New-Item -ItemType Directory -Path $csvCombineFolder
    }

    Write-Host "Combining all csv files into one csv file: $csvCombineFileNoHeaderFullPath"
    Get-ChildItem $csvFolder -Filter *.csv | 
    Sort-Object { $_.BaseName.Split('-')[2]} |
    Select-Object -ExpandProperty FullName |
    ForEach-Object { 
        Get-Content $_ | Select-Object -Skip 1 
    } |
    Set-Content -Path "$csvCombineFileNoHeaderFullPath" -Force

    Write-Host "Adding header to csv file: $csvCombineFileFullPath"
    Import-Csv -Path $csvCombineFileNoHeaderFullPath -Header "Open time","Open","High","Low","Close","Volume","Close time","Quote asset volume","Number of trades","Taker buy base asset volume","Taker buy quote asset volume","Ignore" |
    Export-Csv -Path $csvCombineFileFullPath -NoTypeInformation -Force
    Remove-Item $csvCombineFileNoHeaderFullPath -Force
}

# Examples
#Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT' -TimeFrame '5m' -StartDate (Get-Date "2017-01-01") -EndDate (Get-Date)
#Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT' -TimeFrame '5m'
<#
.Synopsis
   Get Binance historical data
.DESCRIPTION
   Get Binance historical data for spot or futur, for multitimeframe , multi pairs
.EXAMPLE
   Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT' -TimeFrame '5m'
.EXAMPLE
   Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol 'BTCUSDT', 'ETHUSDT' -TimeFrame '5m', '15m'
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

        # one or many symbols
        [string[]]
        $Symbol='BTCUSDT',

        # one or many time frames
        [string[]]
        $TimeFrame='5m'
    )

    $baseUri = 'https://data.binance.vision/?prefix=data'
    $Uri = "$baseUri/$ContractType/$BulkSize/$Symbol/$TimeFrame"

    $query = Invoke-RestMethod -Method Get -Uri $Uri

    $query

}

$startDate = Get-Date "2017-01-01"
$endDate = Get-Date

while ($endDate -ge $startDate) {
    $year = $endDate.Year
    $month = $endDate.Month.ToString("D2")
    $zipFileName = "BTCUSDT-5m-$year-$month.zip"
    $endDate = $endDate.AddMonths(-1)
    Invoke-RestMethod -Method Get -Uri "https://data.binance.vision/data/spot/monthly/klines/BTCUSDT/5m/$zipFileName" -OutFile $zipFileName
}

# Unzip all in a folder

# combine csv files in one file

$csvFolder = 'C:\temp\BinanceHistData\BTCUSDT-5m-files'
$outputFile = 'C:\temp\BinanceHistData\BTCUSDT-5m-file\BTCUSDT-5m.csv'

Get-ChildItem $csvFolder -Filter *.csv | 
    Sort-Object { $_.BaseName.Split('-')[2]} |
    Select-Object -ExpandProperty FullName |
    ForEach-Object { 
        Get-Content $_ | Select-Object -Skip 1 
    } |
    Set-Content $outputFile

#Import-Csv -Path $outputFile -Header "Open time","Open","High","Low","Close","Volume","Close time","Quote asset volume","Number of trades","Taker buy base asset volume","Taker buy quote asset volume","Ignore" |
#    Export-Csv -Path $outputFile -NoTypeInformation
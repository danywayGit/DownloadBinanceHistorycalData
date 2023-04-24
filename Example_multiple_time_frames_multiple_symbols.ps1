# dot source function
. .\GetBinanceHistoricalData.ps1

#get historical data for multiple binance pairs and multiple timeframes
$timeFrames = '1m', '5m', '15m', '1h', '4h', '1d'
$symbols = 'ETHUSDT', 'LINKUSDT', '1INCHUSDT', 'COMPUSDT', 'AAVEUSDT'

foreach ($symbol in $symbols) {
    foreach ($timeFrame in $timeFrames) {
        Get-BinanceHistoricalData -ContractType 'spot' -BulkSize 'monthly' -Symbol $symbol -TimeFrame $timeFrame -StartDate (Get-Date "2017-01-01") -EndDate (Get-Date)
    }
}
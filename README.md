# DownloadBinanceHistorycalData

## Required powershell module
    ThreadJob

## Main information page
https://www.binance.com/en/landing/data
https://github.com/binance/binance-public-data

## Example of zip file per day, where each file contain 5 minutes candles data (~15k per file)
https://data.binance.vision/?prefix=data/spot/daily/klines/BTCUSDT/5m/

## Example of zip file per month, where each file contain 5 minutes candles data (~450k per file)
https://data.binance.vision/?prefix=data/spot/monthly/klines/BTCUSDT/5m/

## Required python module
    requests
    pandas

## requirements.txt file content python dependencies

## Create and install dependencies in a virtual environment on Windows    
    python -m venv venv-historicaldata
    .\venv-historicaldata\Scripts\activate
    pip3 install -r .\requirements.txt
# import function
from datetime import datetime
from GetBinanceHistoricalData import get_binance_historical_data

#get historical data for multiple binance pairs and multiple timeframes
time_frames = '1m', '5m', '15m', '30m', '1h', '4h', '12h', '1d'
symbols = 'ADAUSDT', 'ATOMUSDT'

for symbol in symbols:
    for time_frame in time_frames:
        get_binance_historical_data(contract_type='spot',
                                     bulk_size='monthly', 
                                     symbol=symbol, 
                                     time_frame=time_frame,
                                     start_date=datetime(2017, 1, 1),
                                     end_date=datetime.now()
        )
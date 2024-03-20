import os
import requests
import csv
from datetime import datetime
from zipfile import ZipFile, is_zipfile

#contract_type can be 'spot' or 'futures'
#bulk_size can be 'monthly' or 'daily'
#time_frame can be '1mo','1w','3d','1d','12h', '8h', '6h', '4h', '2h', '1h', '30m', '15m', '5m', '3m', '1m', '1s'
def get_binance_historical_data(contract_type='spot', bulk_size='monthly', symbol='BTCUSDT', time_frame='5m', start_date=datetime(2017, 1, 1), end_date=datetime.now()):   
    # Check if start date is before end date
    if start_date > end_date:
        raise ValueError("Start date must be before end date")

    # Check if start date is before 2017-01-01
    if start_date < datetime(2017, 1, 1):
        raise ValueError("Start date must be after 2017-01-01")

    # Check if end date is after today
    if end_date > datetime.now():
        raise ValueError("End date must be before today")

    # Download all zip files
    base_uri = 'https://data.binance.vision/data'
    uri = f"{base_uri}/{contract_type}/{bulk_size}/klines/{symbol}/{time_frame}"

    zip_folder = f"{symbol}-{time_frame}-zip-files"
    os.makedirs(zip_folder, exist_ok=True)

    print(f"Downloading historical data for symbol {symbol} for contact type {contract_type} for the {time_frame} timeframe from {start_date} to {end_date}, in folder {zip_folder}")

    files = []
    while end_date >= start_date:
        year = end_date.year
        month = str(end_date.month).zfill(2)
        zip_file_name = f"{symbol}-{time_frame}-{year}-{month}.zip"
        
        if end_date.month == 1:
            end_date = end_date.replace(year = end_date.year - 1, month = 12)
        else:
            end_date = end_date.replace(month = end_date.month - 1)
        
        file_to_download = f"{uri}/{zip_file_name}"
        downloaded_file_path = f"{zip_folder}/{zip_file_name}"
        files.append({
            "uri": file_to_download,
            "out_file": downloaded_file_path
        })
        
    with requests.Session() as session:
        for file in files:
            try:
                response = session.head(file["uri"])
                if response.status_code == 200:
                    remote_file_size = int(response.headers.get('content-length', 0))
                    if os.path.exists(file["out_file"]):
                        local_file_size = os.path.getsize(file["out_file"])
                        if abs(local_file_size - remote_file_size) <= 0.1 * remote_file_size:
                            print(f"File {file['out_file']} already exists and is approximately the same size. Skipping download.")
                            continue
                    # If file doesn't exist or size is different, download it
                    response = session.get(file["uri"])
                    with open(file["out_file"], 'wb') as f:
                        f.write(response.content)
                else:
                    print(f"Warning: file {file['uri']} could not be downloaded")
            except requests.exceptions.RequestException as e:
                print(f"Warning: {e}")

    print("Download complete")

    csv_folder = f"{symbol}-{time_frame}-csv-files"
    os.makedirs(csv_folder, exist_ok=True)

    print(f"Unzipping all csv files from all zip files into the folder: {csv_folder}")
    for file in os.listdir(zip_folder):
        if file.endswith(".zip"):
            file_path = os.path.join(zip_folder, file)
            if is_zipfile(file_path):
                with ZipFile(file_path, 'r') as zip_ref:
                    zip_ref.extractall(csv_folder)
            else:
                print(f"{file_path} is not a zip file")

    # Combine
    csv_combine_folder = symbol
    csv_combine_file_no_header = f"{symbol}-{time_frame}-noheader.csv"
    csv_combine_file_no_header_full_path = f"{csv_combine_folder}/{csv_combine_file_no_header}"
    csv_combine_file = f"{symbol}-{time_frame}.csv"
    csv_combine_file_full_path = f"{csv_combine_folder}/{csv_combine_file}"
    os.makedirs(csv_combine_folder, exist_ok=True)

    # Get a list of all CSV files in the directory
    csv_files = [file for file in os.listdir(csv_folder) if file.endswith('.csv')]

    # Open the output file in write mode
    with open(csv_combine_file_no_header_full_path, 'w', newline='') as outfile:
        writer = csv.writer(outfile)

        # Process each file
        for i, csv_file in enumerate(csv_files):
            # Open each CSV file in read mode
            with open(os.path.join(csv_folder, csv_file), 'r') as infile:
                print(f'Processing file {i + 1}/{len(csv_files)}: {csv_file}')
                reader = csv.reader(infile)

                # Write the header to the output file only once
                if i == 0:
                    writer.writerow(next(reader))

                # Write the data rows to the output file
                writer.writerows(reader)

    print('CSV file without header saved successfully.')
    
    print('Adding header to the combined CSV file...')
    # Define the header
    header = ["Open time","Open","High","Low","Close","Volume","Close time","Quote asset volume","Number of trades","Taker buy base asset volume","Taker buy quote asset volume","Ignore"]

    # Open the combined CSV file in read mode and read its content
    with open(csv_combine_file_no_header_full_path, 'r') as infile:
        reader = csv.reader(infile)
        rows = list(reader)

    # Open the combined CSV file in write mode, write the header and the original content
    with open(csv_combine_file_full_path, 'w', newline='') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(header)
        writer.writerows(rows)
        
    print(f"Finale CSV file {csv_combine_file_full_path} saved successfully.")
        
    print(f"Removing temporary CSV file without header {csv_combine_file_no_header_full_path}.")
    # Remove the file without header
    os.remove(csv_combine_file_no_header_full_path)


# Examples
#get_binance_historical_data(contract_type='spot', bulk_size='monthly', symbol='BTCUSDT', time_frame='5m', start_date=datetime(2017, 1, 1), end_date=datetime.now())
#get_binance_historical_data(contract_type='spot', bulk_size='monthly', symbol='BTCUSDT', time_frame='5m')
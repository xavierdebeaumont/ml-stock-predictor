from yahoofinancials import YahooFinancials
from datetime import datetime, timedelta
from google.cloud import storage
import csv
from io import StringIO

ls_ticker = 'AI.PA'
yahoo_financials = YahooFinancials(ls_ticker)

today = datetime.today()
start_date = (today - timedelta(days=5)).strftime("%Y-%m-%d")  # generate daily file for last 5 days
end_date = today.strftime("%Y-%m-%d")

def upload_csv_gcs(data_dictionary, bucket_name, blob_name):
    data_dict = data_dictionary
    data_dict_keys = data_dictionary[0].keys()

    # Creating a file buffer
    file_buff = StringIO()

    # Writing CSV data to file buffer
    writer = csv.DictWriter(file_buff, fieldnames=data_dict_keys)
    writer.writeheader()
    for data in data_dict:
        writer.writerow(data)

    # Uploading file to GCS
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.upload_from_string(file_buff.getvalue(), content_type='text/csv')
    print('Done uploading to GCS')

def load_data(request):
    stock_prices = yahoo_financials.get_historical_price_data(start_date, end_date, 'daily')
    table_data = stock_prices[ls_ticker]['prices']
    for l in table_data:
        l.pop('date')
        l['ticker'] = ls_ticker
    table_rows = len(table_data)

    # Create CSV and upload to GCS bucket
    dt_string = datetime.now().strftime("%Y-%m-%d_%H%M")
    csv_file_name = ls_ticker + '_' + dt_string + '.csv'
    upload_csv_gcs(table_data, 'your-gcs-bucket-name', csv_file_name)

    response = {
        "Rows": table_rows,
        "body": table_data
    }

    return response

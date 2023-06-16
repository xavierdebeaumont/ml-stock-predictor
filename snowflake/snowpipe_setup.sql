CREATE OR REPLACE STORAGE INTEGRATION gcs_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = GCS
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('gcs://data_lake_datatalks-386314/stocks/');

DESC STORAGE INTEGRATION gcs_integration;

GRANT USAGE ON INTEGRATION GCS_INTEGRATION TO ROLE ACCOUNTADMIN;

CREATE OR REPLACE FILE FORMAT csv
 type='csv'
 field_delimiter = ','
 record_delimiter = '\n'
 skip_header = 1;

 CREATE OR REPLACE STAGE price_pred_gcs_stage
 storage_integration = gcs_integration
 file_format = csv
 url = 'gcs://data_lake_datatalks-386314/stocks/';

 list @price_pred_gcs_stage;

CREATE NOTIFICATION INTEGRATION my_notification_int
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = GCP_PUBSUB
  ENABLED = true
  GCP_PUBSUB_SUBSCRIPTION_NAME = 'projects/datatalks-386314/subscriptions/event_file';

DESC NOTIFICATION INTEGRATION my_notification_int;

create or replace pipe get_stocks_data_pipe
 auto_ingest=true
 INTEGRATION = 'MY_NOTIFICATION_INT'
 as
 copy into historical_prices from @price_pred_gcs_stage
 file_format=csv
 pattern = '.*csv.*'
 on_error = 'Continue';

select count(*) from historical_prices order by date desc;
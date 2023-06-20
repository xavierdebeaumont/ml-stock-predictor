# ml-stock-predictor

## Project

The project will take data from the yahoofincancial api. The data will be fetched every day for the day before then stored in a gcs. Then data will be copy into snowflake through a snowpipe runned with pub/sub. We will try to analyze trendings the data, build a machine learning model and serve it in a streamlit webapp.

## Tools & Technologies

**- Cloud infrastructure:** Created the cloud infra with terraform.

**- Data collection:** Automatically download the stock historical prices data in csv format and save it GCS bucket.

**- Data storage:** Store the data in a Snowflake data warehouse by creating data pipe between GCP and Snowflake.

**- Data Extraction:** Extract & Pre-process the data using Python and perform basic Exploratory Data Analysis.

**- Machine Learning:** Model development: Develop a machine learning model, Train the model on historical data, Evaluate the model and perform hyper parameter tuning

**- Machine Learning:** Model deployment: Deploy the final model on Snowflake.

**- Web App development:** Build a web app using Streamlit and Python to interact with the deployed model and display the predictions.

## Webapp

A streamlit app to display info about stocks. You can then make a prediction about the futur trends and select how much day you want to predict.

![streamlit-app](media/streamlit-stock-prediction.gif)


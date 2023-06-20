#Import dependencies
import streamlit as st
from snowflake.snowpark.session import Session
from plotly import graph_objs as go
import pandas as pd
import json

accountname = st.secrets["SNOWFLAKE"]["account"]
user = st.secrets["SNOWFLAKE"]["user"]
password = st.secrets["SNOWFLAKE"]["password"]
role = st.secrets["SNOWFLAKE"]["role"]
database = st.secrets["SNOWFLAKE"]["database"]
schema = st.secrets["SNOWFLAKE"]["schema"]
warehouse = st.secrets["SNOWFLAKE"]["warehouse"]

#Setting page config
st.set_page_config(
     page_title="Air Liquide Price Prediction",
     page_icon="💹",
     initial_sidebar_state="expanded",
 )

#Create Session object
def create_session_object():
    connection_parameters = {
            "account": accountname,
            "user": user,
            "password": password,
            "role": role,
            "database": database,
            "schema": schema,
            "warehouse": warehouse,
            "ocsp_fail_open":"False"
        }

    session = Session.builder.configs(connection_parameters).create()

    print(session.sql('select current_warehouse(), current_database(), current_schema()').collect())
    return session

#Extract the data from SnowFlake load on pandas DataFrame 
def fetch_data(session):
    rows = session.sql('SELECT * FROM historical_prices').collect()
    data = [row.asDict() for row in rows]
    df = pd.DataFrame(data)
    df.drop_duplicates(subset='DATE', keep="last", inplace=True)
    df = df.sort_values(by='DATE', ascending=False)
    df = df.dropna(how='any')
    return df

    
#Setting web page Title
st.title('Stock Price Prediction')

#Drop down selection for Ticker 
#Currently there is Only one option Google, can add more options like stocks = ('GOOG','AAPL')
stocks = ('AI.PA',)
selected_stock = st.selectbox('Select Ticker', stocks)


if __name__ == "__main__":

    #Creating snowflake session
    session = create_session_object()

    data_load_state = st.text('Loading stock info...')
    
    #Fetching the data 
    price_df = fetch_data(session)
    
    data_load_state.text('Loading data... done!')

    st.subheader('Price History')
    
    #Displaying historical pricing data 
    st.dataframe(price_df)
       
    st.subheader('Price Evolution')

    #Visualizing price history
    trace = go.Scatter(x=price_df['DATE'], y=price_df['CLOSE'],line_color='deepskyblue')

    data = [trace]
    config_layout = dict(
        xaxis=dict(
            rangeselector=dict(
                buttons=list([
                    dict(count=1,
                        label='1m',
                        step='month',
                        stepmode='backward'),
                    dict(count=12,
                        label='1Y',
                        step='month',
                        stepmode='backward'),
                    dict(count=5,
                        label='5Y',
                        step='year',
                        stepmode='backward'),
                    dict(step="all")
                ])
            ),
            title='Date',
            rangeslider=dict(
                visible = True
            ), type='date'
        ),
        yaxis=dict(title='Closing Price')
    )
    fig = dict(data=data, layout=config_layout)
    st.plotly_chart(fig)

    #Slider to select number of days that will be predicted
    days = st.slider('Select No. of days for prediction', 1, 1852,180)
    
    #Chose between showing or not the price history
    show_history = st.selectbox(
        "Show price history?",
        ("N", "Y")
    )

    #Run the prediction on click
    if st.button('Make Predictions'):
        
        prediction_state = st.text('Predicting Future Prices...')

        #Calling snowflake stored procedure 
        pred_list = session.sql(
                "call sproc_predict_using_prophet('{}', '{}',{})".format('historical_prices',show_history, days)   
                ).collect()

        #Load the Prediction data from stored procedure into DataFrame 
        pred_df = pd.DataFrame(json.loads(pred_list[0][0]))
        pred_df = pred_df[['ds','yhat']]
        pred_df['ds'] = pd.to_datetime(pred_df['ds']).dt.date
        pred_df.columns = ['DATE', 'CLOSE']
        pred_df.sort_values(by='DATE',inplace=True)
        
        st.subheader('Predicted Prices')

        #Display the result of the prediction
        st.dataframe(pred_df)
        st.subheader('Predicted Price Trend')

        trace0 = go.Scatter(x=price_df['DATE'], y=price_df['CLOSE'],line_color='deepskyblue', name='Actual Prices')

        trace1 = go.Scatter(x=pred_df['DATE'], y=pred_df['CLOSE'],line_color='lime', name='Predicted Prices')

        #Displaying the price history vs the prediction
        data = [trace0, trace1]
        config_layout = dict(
            title='History vs Prediction',
            xaxis=dict(
                rangeselector=dict(
                    buttons=list([
                        dict(count=1,
                            label='1m',
                            step='month',
                            stepmode='backward'),
                        dict(count=12,
                            label='1Y',
                            step='month',                     
                            stepmode='backward'),
                        dict(count=5,
                            label='5Y',
                            step='year',
                            stepmode='backward'),
                        dict(step="all")
                    ])
                ),
                title='Date',
                rangeslider=dict(
                    visible = True
                ), type='date'
            ),
            yaxis=dict(title='Closing Price')
        )
        fig = dict(data=data, layout=config_layout)
        st.plotly_chart(fig)
        prediction_state.text('Prediction Finished!')
import streamlit as st
from snowflake_function.snowflake_connection_debug import snowflake_connection as sfconnectiondebug 
import pandas as pd
import time
import os

st.title('1 -)BigQuery to Snowflake Migration Using DBT Tool with Automated Testing')
st.link_button("link to Blog","https://medium.com/@csaravanakd/bigquery-to-snowflake-migration-using-dbt-tool-with-automated-testing-4df1ed4fb6b3")
st.write("This project aims to migrate data from BigQuery to Snowflake leveraging the DBT (Data Build Tool) for efficient transformation and loading processes. The migration process includes automating tests to ensure data accuracy and consistency throughout the migration.")
st.divider()
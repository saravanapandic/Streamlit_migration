import streamlit as st 
import snowflake.connector
import pandas as pd
import re





class snowflake_connection:
    def __init__(self,accountname,username,password,warehouse,role) -> None:
        self.accountname=accountname
        self.username=username
        self.password=password
        self.warehouse=warehouse
        self.role=role 
    def connection_debug(self):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
            cursor.execute("SELECT CURRENT_TIMESTAMP")
            # Fetch the result
            result = cursor.fetchone()
            return 1
        except  Exception as error:
            return 0
    def source_database_list(self):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
             # Execute the SHOW DATABASES statement
            cursor.execute("SHOW DATABASES")
            # Fetch the results into a Pandas DataFrame
            # The result set can be fetched into a DataFrame using the Snowflake Connector's 'fetch_pandas_all' method
            result_set = cursor.fetchall()
                    # Get column names from the cursor description
            columns = [col[0] for col in cursor.description]
            
            # Create a DataFrame from the result set and column names
            df = pd.DataFrame(result_set, columns=columns)
            print('hello')
            df.insert(1, 'select database', True)
            print(df)
            return df.iloc[:, [1, 2]]
        except  Exception as error:
            return 0
    def ddl_get_source(self,DATABASE_NAME):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
             # Execute the SHOW DATABASES statement
            cursor.execute(F"select get_ddl('DATABASE','{DATABASE_NAME}',True)")
            # Fetch the results into a Pandas DataFrame
            # The result set can be fetched into a DataFrame using the Snowflake Connector's 'fetch_pandas_all' method
            result_set = cursor.fetchall()
                    # Get column names from the cursor description
            columns = [col[0] for col in cursor.description]
            
            # Create a DataFrame from the result set and column names
            df = pd.DataFrame(result_set, columns=columns)
            if len(df)>0:
                print('none')
                return df.iloc[0,0]
        except  Exception as error:
            print(error)
    def Target_execute(self,ddl_script):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
             # Execute the SHOW DATABASES statement
            cursor.execute(f"{ddl_script}")
            # Fetch the results into a Pandas DataFrame
            # The result set can be fetched into a DataFrame using the Snowflake Connector's 'fetch_pandas_all' method
            result_set = cursor.fetchall()
                    # Get column names from the cursor description
            print(result_set)
            print('in target')
        except  Exception as error:
            return 0
    import re

    def restructure_sql_file(self,input_file, output_file,view_file):
        with open(input_file, 'r') as file:
            content = file.read()

        # Patterns to match various statements
        patterns = {
            'database': re.compile(r'(CREATE OR REPLACE DATABASE.*?;)', re.IGNORECASE | re.DOTALL),
            'schema': re.compile(r'(CREATE OR REPLACE SCHEMA.*?;)', re.IGNORECASE | re.DOTALL),
            'masking_policy': re.compile(r'(CREATE OR REPLACE MASKING POLICY.*?;)', re.IGNORECASE | re.DOTALL),
            'table': re.compile(r'(CREATE OR REPLACE TABLE.*?;)', re.IGNORECASE | re.DOTALL),
            'view': re.compile(r'(CREATE OR REPLACE VIEW.*?;)', re.IGNORECASE | re.DOTALL)
        }

        statements = {
            'database': [],
            'schema': [],
            'masking_policy': [],
            'table': [],
            'view': []
        }

        # Find all matching statements
        for key, pattern in patterns.items():
            statements[key].extend(pattern.findall(content))
            content = pattern.sub('', content)

        # Write the non-view statements to the main output file
        with open(output_file, 'w') as file:
            for key in ['database', 'schema', 'masking_policy','table']:
                for statement in statements[key]:
                    file.write(statement + '\n')
            file.write(content)

        # Write the view statements to a separate file
        with open(view_file, 'w') as file:
            for statement in statements['view']:
                file.write(statement + '\n')

        print(f"File restructured and saved as {output_file}")
        print(f"View statements saved as {view_file}")
    def env_set_target(self):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
             # Execute the SHOW DATABASES statement
            cursor.execute('create database Streamlit_migrated')
            # Fetch the results into a Pandas DataFrame
            # The result set can be fetched into a DataFrame using the Snowflake Connector's 'fetch_pandas_all' method
            cursor.execute('''CREATE or replace STAGE Streamlit_migrated.PUBLIC.INTERNAL_DDL ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')''')
        except  Exception as error:
            return 0
    def drop_env_set_target(self):
        try:
            conn = snowflake.connector.connect(
                user=self.username,
                password=self.password,
                account=self.accountname,
                warehouse= self.warehouse)
            cursor = conn.cursor()
            # Execute a simple query to check the connection
                # Execute the SHOW DATABASES statement
            cursor.execute('DROP database Streamlit_migrated')
            # Fetch the results into a Pandas DataFrame
            # The result set can be fetched into a DataFrame using the Snowflake Connector's 'fetch_pandas_all' method
        except  Exception as error:
            return 0



        

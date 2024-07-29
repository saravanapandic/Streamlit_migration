import streamlit as st
from snowflake_function.snowflake_connection_debug import snowflake_connection as sfconnectiondebug 
import pandas as pd
import time
import os

st.write('SnowMigrated:')
st.info("This application facilitates the migration of entire databases, tables, stored procedures, and other components between Snowflake accounts seamlessly and efficiently.")
tab1,tab2,tab3 = st.tabs(["Account configuration","Loaded config","Status"])
st.session_state.connection_count =0


loaded_config_type=" "
@st.experimental_fragment
def snowflake_connection_debug(pointer_value):
    return_value=pointer_value.connection_debug()
    if return_value==1:
        st.success('Success of connection')
        st.session_state.connection_count +=1  
    elif return_value==0:
        st.error('error on connection')
        st.session_state.connection_count -=1 
    

    
with tab1:
    col1,col2=st.columns([2,2])
    with col1:  
        st.write('Enter source snowflake account related Details')
        source_account=st.form("source_account")
        source_account.text_input('snowflake account:',key='snowflake_account_source')
        source_account.text_input('snowflake username:',key='snowflake_username_source')
        source_account.text_input('snowflake password:',key='snowflake_password_source', type="password")
        source_account.text_input('snowflake warehouse:',key='snowflake_warehouse_source')
        pointer_source_snowflake_account=sfconnectiondebug(st.session_state['snowflake_account_source'],st.session_state['snowflake_username_source'],st.session_state['snowflake_password_source'],st.session_state['snowflake_warehouse_source'])
        status_source_account=source_account.form_submit_button('Debug',on_click=snowflake_connection_debug(pointer_source_snowflake_account))
    
         
        
    with col2:
        st.write('Enter Target snowflake account related Details')
        target_account=st.form("Target_account")
        target_account.text_input('snowflake account:',key='snowflake_account_target')
        target_account.text_input('snowflake username:',key='snowflake_username_target')
        target_account.text_input('snowflake password:',key='snowflake_password_target', type="password")
        target_account.text_input('snowflake warehouse:',key='snowflake_warehouse_target')
        pointer_target_snowflake_account=sfconnectiondebug(st.session_state['snowflake_account_target'],st.session_state['snowflake_username_target'],st.session_state['snowflake_password_target'],st.session_state['snowflake_warehouse_target'])
        status_target_account=target_account.form_submit_button('Debug',on_click=snowflake_connection_debug(pointer_target_snowflake_account))
    if (st.session_state.connection_count ==2):
        st.success('all connection success(source and target)')
    else:
        st.error("error on connection")
current_directory = os.getcwd()
current_directory = current_directory.replace("\\", "/")
   
        
with tab2:
    
    if st.session_state.connection_count==2:
        loaded_config_type = st.radio(
            "Select Copy behavior",
            ["Flatten hierarchy", "Preserve hierarchy", "Merge file "],
            captions=["Will loaded all object ","Will loaded select object only","loaded exists table data",],horizontal=True)
        col1_config,col2_config=st.columns([2,2])
    else:
        st.error("snowflake connection failed")
        

    if loaded_config_type == "Flatten hierarchy":
        with col1_config:
            st.info('this select database inside all object will migrated to target account')
            @st.experimental_fragment
            def snowflake_Database_fetch(pointer_value):
                return_value=pointer_value.source_database_list()
                print(return_value)
                return return_value
            st.dataframe(snowflake_Database_fetch(pointer_source_snowflake_account),column_config={"favorite": st.column_config.CheckboxColumn("Your favorite?",help="Select your **favorite** widgets",default=False,)})
        with col2_config:
            st.title(":blue[object able Migrated] :sunglasses::")  
            st.markdown("""
                    - **Alerts**: 
                    - **Databases**:
                    - **Dynamic Tables**: 
                    - **Event Tables**: 
                    - **External Tables**:
                    - **File Formats**:
                    - **Hybrid Tables**: 
                    - **Iceberg Tables**: 
                    - **Pipes**: 
                    - **Policies**:
                    - **Schemas**:
                    - **Sequences**: 
                    - **Storage Integrations**: 
                    - **Stored Procedures**:
                    - **Streams**:
                    - **Tables**: 
                    - **Tags**: 
                    - **Tasks**: 
                    - **UDFs **:
                    """
                )
        if st.button('Migrated->'):
            progress_text ="Migration operation is currently in progress. Please wait for its completion."
            frame_ddl_value=snowflake_Database_fetch(pointer_source_snowflake_account)
            len_frame_ddl=len(snowflake_Database_fetch(pointer_source_snowflake_account))
            progess_bar= st.progress(0, text=progress_text)
            print(len_frame_ddl)

            @st.experimental_fragment
            def snowflake_ddl_GET_SNOWFLAKE(pointer_value,database):
                return_value=pointer_value.ddl_get_source(database)
                print(type(return_value))
                return (return_value)
            
            
            
            for i in range (len_frame_ddl):
                Holding_ddl=snowflake_ddl_GET_SNOWFLAKE(pointer_source_snowflake_account,frame_ddl_value.iloc[i,1])
                file_path = f'{current_directory }\snowflake_function\ddl_file\output.sql'
                view_file= f'{current_directory }\snowflake_function\ddl_file\DDL_view.sql'
                if Holding_ddl is not None:
                # Append the variable value to the file
                    with open(file_path, 'a') as file:
                        file.write(Holding_ddl + '\n')
                    # pointer_target_snowflake_account.Target_execute(Holding_ddl)
               
                st.toast(f'all object in {frame_ddl_value.iloc[i,1]} are created',  icon='✅')
                if (len_frame_ddl/2)>=i:
                    progess_bar.progress(50, text=progress_text)
                elif (len_frame_ddl)==i+1:
                    progess_bar.progress(100, text=progress_text)
                    st.success('completed')
                    snowflake_stage = '@Streamlit_migrated.PUBLIC.INTERNAL_DDL'
                    pointer_target_snowflake_account.restructure_sql_file(file_path,file_path,view_file)
                    pointer_target_snowflake_account.env_set_target()
                    put_command = f"PUT file://{file_path} {snowflake_stage} AUTO_COMPRESS=FALSE"
                    EXECUTE_COMMAND='EXECUTE IMMEDIATE FROM @SP_DEV.PUBLIC.MY_INT_STAGE/output.sql'
                    pointer_target_snowflake_account.Target_execute(put_command)
                    pointer_target_snowflake_account.Target_execute(EXECUTE_COMMAND)
                    pointer_target_snowflake_account.drop_env_set_target()
    
    else:
        st.write("We are currently making progress with Streamlit, but we have a fully completed solution for the application available in a Docker container. If you need access to this container, please connect with us. The container is provided as an entirely free resource, ensuring ease of access and implementation.")
    




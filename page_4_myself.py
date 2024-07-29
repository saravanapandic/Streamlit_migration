import streamlit as st
from snowflake_function.snowflake_connection_debug import snowflake_connection as sfconnectiondebug 
import pandas as pd
import time
import os
a='''
Hi all, 

I’m **Saravana**, a Data Engineer with extensive experience in designing and developing robust data pipelines. This application I’ve created is designed to facilitate the migration of data from one Snowflake account to another. It represents the intersection of my professional work and personal interests, and aims to be a valuable tool for Snowflake developers, showcasing what's possible.

If you’re interested in collaborating on data engineering projects or discussing industry trends, I’d be thrilled to connect. 🤝

Let’s Connect:
I’m eager to engage with professionals, mentors, and experts in information technology and data engineering. Whether you want to discuss best practices, share insights, or explore potential collaborations, feel free to reach out.

📧 Contact:
You can connect with me via LinkedIn messaging or email me at csaravanakd@gmail.com. I’m open to networking and exploring new opportunities together. For urgent matters, please contact me via email.

Thank you for visiting my application! Please note that this is not the final version; it's a work in progress, and the basic version is currently available on Streamlit.'''
st.write(a)

st.link_button('linkedin','www.linkedin.com/in/saravana-pandi-9a9662198')
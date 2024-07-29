import streamlit as st

pages = {
    "Your account" : [
        st.Page("page_1.py", title="Account Setup"),
        st.Page("page_2.py", title="Manage your account")
    ],
    "Developers" : [
        st.Page("page_3.py", title="Art of Possible"),
        st.Page("page_4_myself.py", title="Myself ",icon="😎")
    ]
}

pg = st.navigation(pages)
pg.run()
create or replace view DBT_DEV.DBO.VWCREDITS_BY_DAY(
	DATE,
	CREDITSCONSUMED,
	WAREHOUSE_NAME
) as
SELECT TO_CHAR((START_TIME),'DD/MM/YYYY') AS Date
,SUM(CREDITS_USED) AS CreditsConsumed
,WAREHOUSE_NAME 
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WMH 
WHERE WMH.START_TIME >= DATEADD(DAY, -1, CURRENT_TIMESTAMP()) 
AND WMH.START_TIME <= CURRENT_TIMESTAMP()
GROUP BY  TO_CHAR((START_TIME),'DD/MM/YYYY')
,WAREHOUSE_NAME
ORDER BY Date;
create or replace view DBT_DEV.DBO.VWCREDITS_BY_HOUR(
	"HourOfDay",
	"CreditsConsumed",
	"UsageMonth"
) as
SELECT TO_TIME(START_TIME) AS "HourOfDay"
,      SUM(CREDITS_USED) AS "CreditsConsumed"
,    TO_CHAR(LAST_DAY(START_TIME),'DD/MM/YYYY') AS "UsageMonth"
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WMH 
WHERE WMH.START_TIME >= DATEADD(DAY, 0, CURRENT_DATE())
GROUP BY  TO_TIME(START_TIME)
,    LAST_DAY(START_TIME) 
ORDER BY "HourOfDay";
create or replace view DBT_DEV.DBO.VWCREDITS_PER_MONTH(
	USAGEMONTH,
	CREDITSCONSUMED
) as
SELECT TO_CHAR(START_TIME,'MMMM') AS UsageMonth
,     SUM(CREDITS_USED) AS CreditsConsumed
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WMH 
WHERE WMH.START_TIME >= DATEADD(MONTH, -1, CURRENT_DATE()) 
GROUP BY TO_CHAR(START_TIME,'MMMM')
ORDER BY UsageMonth;
create or replace view DBT_DEV.DBO.VWMONTHLY_CREDITS_BY_TYPE(
	"UsageMonth",
	WAREHOUSE_CREDITS,
	PIPE_CREDITS,
	MVIEW_CREDITS,
	CLUSTERING_CREDITS,
	READER_CREDITS,
	TOTAL
) as
SELECT TO_CHAR(LAST_DAY(USAGE_DATE),'DD/MM/YYYY') AS "UsageMonth"
,      SUM(DECODE(SERVICE_TYPE, 
                  'WAREHOUSE_METERING', CREDITS_BILLED)) AS WAREHOUSE_CREDITS,
       SUM(DECODE(SERVICE_TYPE,
                 'PIPE', CREDITS_BILLED)) AS PIPE_CREDITS,
       SUM(DECODE(SERVICE_TYPE,
                 'MATERIALIZED_VIEW', CREDITS_BILLED)) AS MVIEW_CREDITS,
       SUM(DECODE(SERVICE_TYPE,
                 'AUTO_CLUSTERING', CREDITS_BILLED)) AS CLUSTERING_CREDITS,
       SUM(DECODE(SERVICE_TYPE,
                 'WAREHOUSE_METERING_READER', CREDITS_BILLED)) AS READER_CREDITS
,      SUM(CREDITS_BILLED) AS TOTAL
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY WMH
WHERE WMH.USAGE_DATE >= DATEADD(MONTH, -1, CURRENT_DATE()) 
GROUP BY TO_CHAR(LAST_DAY(USAGE_DATE),'DD/MM/YYYY');
create or replace view DBT_DEV.DBO.VWSTORAGE_USAGE_MONTHLY_SUMMARY(
	"UsageMonth",
	"TotalBillableStorageInTB",
	"BillableStorageInTB",
	"StageStorageInTB",
	"FailSafeStorageInTB"
) as
SELECT 
    TO_CHAR(LAST_DAY(USAGE_DATE),'DD/MM/YYYY') AS "UsageMonth"
  , AVG(STORAGE_BYTES + STAGE_BYTES + FAILSAFE_BYTES) / POWER(1024, 4) AS "TotalBillableStorageInTB"
  , AVG(STORAGE_BYTES ) / POWER(1024, 4) AS "BillableStorageInTB"
  , AVG(STAGE_BYTES ) / POWER(1024, 4) AS "StageStorageInTB"
  , AVG(FAILSAFE_BYTES ) / POWER(1024, 4) AS "FailSafeStorageInTB"
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE
WHERE USAGE_DATE >= DATEADD(MONTH, -1, CURRENT_DATE()) 
GROUP BY TO_CHAR(LAST_DAY(USAGE_DATE),'DD/MM/YYYY') 
ORDER BY TO_CHAR(LAST_DAY(USAGE_DATE),'DD/MM/YYYY');
create or replace view DBT_DEV.DBO.VWUSER_ACTIVITY(
	USER_NAME,
	ROLE_NAME,
	TOTAL_QUERIES,
	ESTIMATED_CREDITS,
	USAGEMONTH
) as
WITH USER_ACTIVITY AS
(
SELECT USER_NAME,ROLE_NAME, COUNT(*) TOTAL_QUERIES, 
       SUM(TOTAL_ELAPSED_TIME/1000 * 
       CASE UPPER(WAREHOUSE_SIZE)
            WHEN 'X-SMALL' THEN 1/60/60
            WHEN 'SMALL'   THEN 2/60/60
            WHEN 'MEDIUM'  THEN 4/60/60
            WHEN 'LARGE'   THEN 8/60/60
            WHEN 'X-LARGE' THEN 16/60/60
            WHEN '2X-LARGE' THEN 32/60/60
            WHEN '3X-LARGE' THEN 64/60/60
            WHEN '4X-LARGE' THEN 128/60/60
       ELSE 0
       END) AS ESTIMATED_CREDITS
       , TO_CHAR(START_TIME,'MMMM') AS UsageMonth 
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE WAREHOUSE_NAME IS NOT NULL AND WAREHOUSE_SIZE IS NOT NULL
AND START_TIME >= DATEADD(DAY, -1, CURRENT_TIMESTAMP()) 
AND START_TIME <= CURRENT_TIMESTAMP()
GROUP BY USER_NAME,ROLE_NAME,TO_CHAR(START_TIME,'MMMM')
)
SELECT * FROM USER_ACTIVITY
ORDER BY ESTIMATED_CREDITS;
create or replace view DBT_DEV.DBO.VWUSER_ACTIVITY_PERMONTH(
	USER_NAME,
	ROLE_NAME,
	TOTAL_QUERIES,
	ESTIMATED_CREDITS,
	USAGEMONTH
) as
WITH USER_ACTIVITY AS
(
SELECT USER_NAME,ROLE_NAME, COUNT(*) TOTAL_QUERIES, 
       SUM(TOTAL_ELAPSED_TIME/1000 * 
       CASE UPPER(WAREHOUSE_SIZE)
            WHEN 'X-SMALL' THEN 1/60/60
            WHEN 'SMALL'   THEN 2/60/60
            WHEN 'MEDIUM'  THEN 4/60/60
            WHEN 'LARGE'   THEN 8/60/60
            WHEN 'X-LARGE' THEN 16/60/60
            WHEN '2X-LARGE' THEN 32/60/60
            WHEN '3X-LARGE' THEN 64/60/60
            WHEN '4X-LARGE' THEN 128/60/60
       ELSE 0
       END) AS ESTIMATED_CREDITS
       , TO_CHAR(START_TIME,'MMMM') AS UsageMonth 
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE WAREHOUSE_NAME IS NOT NULL AND WAREHOUSE_SIZE IS NOT NULL
AND START_TIME >= DATE_TRUNC(month, CURRENT_DATE())
GROUP BY USER_NAME,ROLE_NAME,TO_CHAR(START_TIME,'MMMM')
)
SELECT * FROM USER_ACTIVITY
ORDER BY ESTIMATED_CREDITS;
create or replace view DBT_DEV.DBO.VWWAREHOUSE_METERING_HISTORY(
	START_TIME,
	END_TIME,
	WAREHOUSE_ID,
	WAREHOUSE_NAME,
	CREDITS_USED,
	START_DATE,
	WAREHOUSE_OPERATION_HOURS,
	TIME_OF_DAY
) as
SELECT "START_TIME",
    "END_TIME",
    "WAREHOUSE_ID",
    "WAREHOUSE_NAME",
    "CREDITS_USED",
     TO_DATE(START_TIME) AS START_DATE,
    DATEDIFF(HOUR, START_TIME, END_TIME) AS WAREHOUSE_OPERATION_HOURS,
    TO_TIME(START_TIME) AS TIME_OF_DAY
FROM "SNOWFLAKE"."ACCOUNT_USAGE"."WAREHOUSE_METERING_HISTORY"
ORDER BY TO_DATE(START_TIME) DESC;
create or replace view ENTAINDEV.DBT_SCH.CUSTOMERS_REVENUE(
	CUSTOMERID,
	CUSTOMERNAME,
	REVENUE
) as (
    SELECT 
ORF.CUSTOMERID,
CS.CUSTOMERNAME,
ORF.REVENUE
FROM ENTAINDEV.DBT_SCH.orders_fact AS ORF
JOIN ENTAINDEV.DBT_SCH.customers_stg AS CS
ON ORF.CUSTOMERID = CS.CUSTOMERID
  );
create or replace view ENTAINDEV.DBT_SCH.ORDERS_FACT(
	ORDERID,
	ORDERDATE,
	CUSTOMERID,
	EMPLOYEEID,
	STOREID,
	STATUSDESC,
	REVENUE
) as (
    SELECT 
OS.ORDERID,
OS.ORDERDATE,
OS.CUSTOMERID,
OS.EMPLOYEEID,
OS.STOREID,
OS.STATUSDESC,
SUM(OT.TOTAL_PRICE) AS REVENUE
FROM 
ENTAINDEV.DBT_SCH.orders_stg AS OS
join ENTAINDEV.DBT_SCH.order_items AS OT
ON OS.ORDERID = OT.ORDERID
GROUP BY 
OS.ORDERID,
OS.ORDERDATE,
OS.CUSTOMERID,
OS.EMPLOYEEID,
OS.STOREID,
OS.STATUSDESC
  );
create or replace view ENTAINDEV.DBT_SCH.ORDERS_STG(
	ORDERID,
	ORDERDATE,
	CUSTOMERID,
	EMPLOYEEID,
	STOREID,
	STATUSCD,
	STATUSDESC
) as (
    SELECT ORDERID,

ORDERDATE,

CUSTOMERID,

EMPLOYEEID,

STOREID,

STATUS AS STATUSCD,

CASE 

    WHEN STATUS = '01' THEN 'IN PROGRESS'

    WHEN STATUS = '02' THEN 'COMPLETED'

    WHEN STATUS = '03' THEN 'CANCELLED'

    ELSE NULL

END AS STATUSDESC

FROM DBT_SCH.ORDERS
  );
create or replace view ENTAINDEV.DBT_SCH.ORDER_ITEMS(
	ORDERITEMID,
	ORDERID,
	PRODUCTID,
	QUANTITY,
	UNITPRICE,
	TOTAL_PRICE
) as (
    SELECT 

ORDERITEMID,

ORDERID,

PRODUCTID,

QUANTITY,

UNITPRICE,

QUANTITY * UNITPRICE AS TOTAL_PRICE

FROM DBT_SCH.ORDERITEMS
  );
create or replace view ENTAINDEV.DBT_SCH.ORDER_ITEMS_UNIQ(
	ORDERITEMID,
	ORDERID,
	PRODUCTID,
	QUANTITY,
	UNITPRICE,
	UPDATED_AT
) as (
    select *
    from ENTAINDEV.DBT_SCH.orderitems
    qualify
        row_number() over (
            partition by OrderID
            order by updated_at desc
        ) = 1
  );
create or replace view ENTAINDEV.DBT_SCH.SIMPLE_JINJA_CODE(
	NUMBER
) as (
    


    SELECT 0 AS number
        
            UNION
        

    SELECT 1 AS number
        
            UNION
        

    SELECT 2 AS number
        
            UNION
        

    SELECT 3 AS number
        
            UNION
        

    SELECT 4 AS number
        
            UNION
        

    SELECT 5 AS number
        
            UNION
        

    SELECT 6 AS number
        
            UNION
        

    SELECT 7 AS number
        
            UNION
        

    SELECT 8 AS number
        
            UNION
        

    SELECT 9 AS number
        

  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.MY_SECOND_DBT_MODEL(
	ID
) as (
    -- Use the `ref` function to select from other models

select *
from PC_DBT_DB.DBT_SELUMALAI.my_first_dbt_model
where id = 1
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.STG_LINE_ITEMS(
	ORDER_ITEM_KEY,
	ORDER_KEY,
	PART_KEY,
	SUPPLIER_KEY,
	LINE_NUMBER,
	QUANTITY,
	EXTENDED_PRICE,
	DISCOUNT_PERCENTAGE,
	TAX_RATE,
	RETURN_FLAG,
	STATUS_CODE,
	SHIP_DATE,
	COMMIT_DATE,
	RECEIPT_DATE,
	SHIP_INSTRUCTIONS,
	SHIP_MODE,
	COMMENT
) as (
    with source as (

    select * from snowflake_sample_data.tpch_sf1.lineitem

),

renamed as (

    select
    
        md5(cast(coalesce(cast(l_orderkey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(l_linenumber as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
                as order_item_key,
        l_orderkey as order_key,
        l_partkey as part_key,
        l_suppkey as supplier_key,
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount_percentage,
        l_tax as tax_rate,
        l_returnflag as return_flag,
        l_linestatus as status_code,
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,
        l_shipinstruct as ship_instructions,
        l_shipmode as ship_mode,
        l_comment as comment

    from source

)

select * from renamed
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.STG_ORDERS(
	ORDER_KEY,
	CUSTOMER_KEY,
	STATUS_CODE,
	TOTAL_PRICE,
	ORDER_DATE,
	PRIORITY_CODE,
	CLERK_NAME,
	SHIP_PRIORITY,
	COMMENT
) as (
    with source as (

    select * from snowflake_sample_data.tpch_sf1.orders

),

renamed as (

    select

        o_orderkey as order_key,
        o_custkey as customer_key,
        o_orderstatus as status_code,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as priority_code,
        o_clerk as clerk_name,
        o_shippriority as ship_priority,
        o_comment as comment

    from source

)

select * from renamed
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.STG_ORDERS_VM(
	ORDER_KEY,
	CUSTOMER_KEY,
	STATUS_CODE,
	TOTAL_PRICE,
	ORDER_DATE,
	PRIORITY_CODE,
	CLERK_NAME,
	SHIP_PRIORITY,
	COMMENT
) as (
    with source as (

    select * from snowflake_sample_data.tpch_sf1.orders

),

renamed as (

    select

        o_orderkey as order_key,
        o_custkey as customer_key,
        o_orderstatus as status_code,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as priority_code,
        o_clerk as clerk_name,
        o_shippriority as ship_priority,
        o_comment as comment

    from source

)

select * from renamed
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.STG_TPCH_LINE_ITEMS(
	ORDER_ITEM_KEY,
	ORDER_KEY,
	PART_KEY,
	SUPPLIER_KEY,
	LINE_NUMBER,
	QUANTITY,
	EXTENDED_PRICE,
	DISCOUNT_PERCENTAGE,
	TAX_RATE,
	RETURN_FLAG,
	STATUS_CODE,
	SHIP_DATE,
	COMMIT_DATE,
	RECEIPT_DATE,
	SHIP_INSTRUCTIONS,
	SHIP_MODE,
	COMMENT
) as (
    with source as (

    select * from snowflake_sample_data.tpch_sf1.lineitem

),

renamed as (

    select
    
        md5(cast(coalesce(cast(l_orderkey as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(l_linenumber as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))
                as order_item_key,
        l_orderkey as order_key,
        l_partkey as part_key,
        l_suppkey as supplier_key,
        l_linenumber as line_number,
        l_quantity as quantity,
        l_extendedprice as extended_price,
        l_discount as discount_percentage,
        l_tax as tax_rate,
        l_returnflag as return_flag,
        l_linestatus as status_code,
        l_shipdate as ship_date,
        l_commitdate as commit_date,
        l_receiptdate as receipt_date,
        l_shipinstruct as ship_instructions,
        l_shipmode as ship_mode,
        l_comment as comment

    from source

)

select * from renamed
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI.STG_TPCH_ORDERS(
	ORDER_KEY,
	CUSTOMER_KEY,
	STATUS_CODE,
	TOTAL_PRICE,
	ORDER_DATE,
	PRIORITY_CODE,
	CLERK_NAME,
	SHIP_PRIORITY,
	COMMENT
) as (
    with source as (

    select * from snowflake_sample_data.tpch_sf1.orders

),

renamed as (

    select

        o_orderkey as order_key,
        o_custkey as customer_key,
        o_orderstatus as status_code,
        o_totalprice as total_price,
        o_orderdate as order_date,
        o_orderpriority as priority_code,
        o_clerk as clerk_name,
        o_shippriority as ship_priority,
        o_comment as comment

    from source

)

select * from renamed
  );
create or replace view PC_DBT_DB.DBT_SELUMALAI_DBT_TEST__AUDIT.DBT_EXPECTATIONS_EXPECT_ROW_VA_1FCC102F78F3DBCAD680A4442A301EAC(
	MAX_TIMESTAMP
) as (
    

 with max_recency as (

    select max(cast(createtsp as timestamp_ntz)) as max_timestamp
    from
        PC_DBT_DB.DBT_SELUMALAI.time_int
    where
        -- to exclude erroneous future dates
        cast(createtsp as timestamp_ntz) <= convert_timezone('UTC', 'Asia/Kolkata',
    cast(convert_timezone('UTC', current_timestamp()) as timestamp)
)
        
)
select
    *
from
    max_recency
where
    -- if the row_condition excludes all rows, we need to compare against a default date
    -- to avoid false negatives
    coalesce(max_timestamp, cast('1970-01-01' as timestamp_ntz))
        <
        cast(

    dateadd(
        hours,
        -4,
        convert_timezone('UTC', 'Asia/Kolkata',
    cast(convert_timezone('UTC', current_timestamp()) as timestamp)
)
        )

 as timestamp_ntz)




  );
create or replace view PC_DBT_DB.DBT_SELUMALAI_DBT_TEST__AUDIT.NOT_NULL_TIME_INT_CREATETSP(
	ID,
	CREATETSP
) as (
    
    
    



select *
from PC_DBT_DB.DBT_SELUMALAI.time_int
where createtsp is null



  );

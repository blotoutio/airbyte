USE [test_normalization];
    execute('create view _airbyte_test_normalization."dedup_exchange_rate_ab3__dbt_tmp" as
    
with __dbt__CTE__dedup_exchange_rate_ab1 as (

-- SQL model to parse JSON blob stored in a single column and extract into separated field columns as described by the JSON Schema
select
    json_value(_airbyte_data, ''$."id"'') as id,
    json_value(_airbyte_data, ''$."currency"'') as currency,
    json_value(_airbyte_data, ''$."date"'') as "date",
    json_value(_airbyte_data, ''$."timestamp_col"'') as timestamp_col,
    json_value(_airbyte_data, ''$."HKD@spéçiäl & characters"'') as "HKD@spéçiäl & characters",
    json_value(_airbyte_data, ''$."HKD_special___characters"'') as hkd_special___characters,
    json_value(_airbyte_data, ''$."NZD"'') as nzd,
    json_value(_airbyte_data, ''$."USD"'') as usd,
    _airbyte_ab_id,
    _airbyte_emitted_at,
    SYSDATETIME() as _airbyte_normalized_at
from "test_normalization".test_normalization._airbyte_raw_dedup_exchange_rate as table_alias
-- dedup_exchange_rate
where 1 = 1

),  __dbt__CTE__dedup_exchange_rate_ab2 as (

-- SQL model to cast each column to its adequate SQL type converted from the JSON schema type
select
    cast(id as 
    bigint
) as id,
    cast(currency as 
    VARCHAR(max)) as currency,
    try_parse(nullif("date", '''') as date) as "date",
    try_parse(nullif(timestamp_col, '''') as datetime) as timestamp_col,
    cast("HKD@spéçiäl & characters" as 
    float
) as "HKD@spéçiäl & characters",
    cast(hkd_special___characters as 
    VARCHAR(max)) as hkd_special___characters,
    cast(nzd as 
    float
) as nzd,
    cast(usd as 
    float
) as usd,
    _airbyte_ab_id,
    _airbyte_emitted_at,
    SYSDATETIME() as _airbyte_normalized_at
from __dbt__CTE__dedup_exchange_rate_ab1
-- dedup_exchange_rate
where 1 = 1

)-- SQL model to build a hash column based on the values of this record
select
    convert(varchar(32), HashBytes(''md5'',  coalesce(cast(
    
    

    concat(concat(coalesce(cast(id as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast(currency as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast("date" as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast(timestamp_col as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast("HKD@spéçiäl & characters" as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast(hkd_special___characters as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast(nzd as 
    VARCHAR(max)), ''''), ''-'', coalesce(cast(usd as 
    VARCHAR(max)), ''''),''''), '''') as 
    VARCHAR(max)), '''')), 2) as _airbyte_dedup_exchange_rate_hashid,
    tmp.*
from __dbt__CTE__dedup_exchange_rate_ab2 tmp
-- dedup_exchange_rate
where 1 = 1

    ');


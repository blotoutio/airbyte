{#
    Adapter Macros for the following functions:
    - Bigquery: unnest() -> https://cloud.google.com/bigquery/docs/reference/standard-sql/arrays#flattening-arrays-and-repeated-fields
    - Snowflake: flatten() -> https://docs.snowflake.com/en/sql-reference/functions/flatten.html
    - Redshift: -> https://blog.getdbt.com/how-to-unnest-arrays-in-redshift/
    - postgres: unnest() -> https://www.postgresqltutorial.com/postgresql-array/
#}

{# cross_join_unnest -------------------------------------------------     #}

{% macro cross_join_unnest(stream_name, array_col) -%}
  {{ adapter.dispatch('cross_join_unnest')(stream_name, array_col) }}
{%- endmacro %}

{% macro default__cross_join_unnest(stream_name, array_col) -%}
    {% do exceptions.warn("Undefined macro cross_join_unnest for this destination engine") %}
{%- endmacro %}

{% macro bigquery__cross_join_unnest(stream_name, array_col) -%}
    cross join unnest({{ array_col }}) as {{ array_col }}
{%- endmacro %}

{% macro oracle__cross_join_unnest(stream_name, array_col) -%}
    {% do exceptions.warn("Normalization does not support unnesting for Oracle yet.") %}
{%- endmacro %}

{% macro postgres__cross_join_unnest(stream_name, array_col) -%}
    cross join jsonb_array_elements(
        case jsonb_typeof({{ array_col }})
        when 'array' then {{ array_col }}
        else '[]' end
    ) as _airbyte_nested_data
{%- endmacro %}

{% macro mysql__cross_join_unnest(stream_name, array_col) -%}
    left join joined on _airbyte_{{ stream_name }}_hashid = joined._airbyte_hashid
{%- endmacro %}

{% macro redshift__cross_join_unnest(stream_name, array_col) -%}
    left join joined on _airbyte_{{ stream_name }}_hashid = joined._airbyte_hashid
{%- endmacro %}

{% macro snowflake__cross_join_unnest(stream_name, array_col) -%}
    cross join table(flatten({{ array_col }})) as {{ array_col }}
{%- endmacro %}

{# unnested_column_value -- this macro is related to unnest_cte #}

{% macro unnested_column_value(column_col) -%}
  {{ adapter.dispatch('unnested_column_value')(column_col) }}
{%- endmacro %}

{% macro default__unnested_column_value(column_col) -%}
    {{ column_col }}
{%- endmacro %}

{% macro postgres__unnested_column_value(column_col) -%}
    _airbyte_nested_data
{%- endmacro %}

{% macro snowflake__unnested_column_value(column_col) -%}
    {{ column_col }}.value
{%- endmacro %}

{% macro redshift__unnested_column_value(column_col) -%}
    _airbyte_nested_data
{%- endmacro %}

{% macro mysql__unnested_column_value(column_col) -%}
    _airbyte_nested_data
{%- endmacro %}

{% macro oracle__unnested_column_value(column_col) -%}
    {{ column_col }}
{%- endmacro %}

{# unnest_cte -------------------------------------------------     #}

{% macro unnest_cte(table_name, stream_name, column_col) -%}
  {{ adapter.dispatch('unnest_cte')(table_name, stream_name, column_col) }}
{%- endmacro %}

{% macro default__unnest_cte(table_name, stream_name, column_col) -%}{%- endmacro %}

{# -- based on https://blog.getdbt.com/how-to-unnest-arrays-in-redshift/ #}
{% macro redshift__unnest_cte(table_name, stream_name, column_col) -%}
    {%- if not execute -%}
        {{ return('') }}
    {% endif %}
    {%- call statement('max_json_array_length', fetch_result=True) -%}
        with max_value as (
            select max(json_array_length({{ column_col }}, true)) as max_number_of_items
            from {{ ref(table_name) }}
        )
        select
            case when max_number_of_items is not null and max_number_of_items > 1
            then max_number_of_items
            else 1 end as max_number_of_items
        from max_value
    {%- endcall -%}
    {%- set max_length = load_result('max_json_array_length') -%}
with numbers as (
    {{dbt_utils.generate_series(max_length["data"][0][0])}}
),
joined as (
    select
        _airbyte_{{ stream_name }}_hashid as _airbyte_hashid,
        json_extract_array_element_text({{ column_col }}, numbers.generated_number::int - 1, true) as _airbyte_nested_data
    from {{ ref(table_name) }}
    cross join numbers
    -- only generate the number of records in the cross join that corresponds
    -- to the number of items in {{ table_name }}.{{ column_col }}
    where numbers.generated_number <= json_array_length({{ column_col }}, true)
)
{%- endmacro %}

{% macro mysql__unnest_cte(table_name, stream_name, column_col) -%}
    {%- if not execute -%}
        {{ return('') }}
    {% endif %}

    {%- call statement('max_json_array_length', fetch_result=True) -%}
        with max_value as (
            select max(json_length({{ column_col }})) as max_number_of_items
            from {{ ref(table_name) }}
        )
        select
            case when max_number_of_items is not null and max_number_of_items > 1
            then max_number_of_items
            else 1 end as max_number_of_items
        from max_value
    {%- endcall -%}

    {%- set max_length = load_result('max_json_array_length') -%}
    with numbers as (
        {{ dbt_utils.generate_series(max_length["data"][0][0]) }}
    ),
    joined as (
        select
            _airbyte_{{ stream_name }}_hashid as _airbyte_hashid,
            {# -- json_extract(column_col, '$[i][0]') as _airbyte_nested_data #}
            json_extract({{ column_col }}, concat("$[", numbers.generated_number - 1, "][0]")) as _airbyte_nested_data
        from {{ ref(table_name) }}
        cross join numbers
        -- only generate the number of records in the cross join that corresponds
        -- to the number of items in {{ table_name }}.{{ column_col }}
        where numbers.generated_number <= json_length({{ column_col }})
    )
{%- endmacro %}

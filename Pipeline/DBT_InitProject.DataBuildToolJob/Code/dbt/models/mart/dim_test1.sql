SELECT 'Hello, World!' AS greeting;


-- {{ config(
--     materialized         = 'incremental',
--     unique_key           = [this.name+'ScdId', 'EffDate'],
--     on_schema_change     = 'sync_all_columns'
-- ) }}

-- {% set model_definition = {'this' : this.database + '.' + this.schema + '.' + this.name,  
--                            'name' : this.name,                           
--                             'target_exists' :  is_incremental() ,
--                             'record_identifier' : 'BusinessKey', 
--                             'type_0_cols' : ['InsertedDate'],
--                             'type_1_cols' : ['ModifiedDate'],
--                             'type_2_cols' : ['DivisionCode', 'Name', 'Calendar', 'Country', 'Region', 'Language'] } %}

-- WITH
-- untransformed AS (
--     SELECT
--         DivisionCode,
--         DivisionCode as BusinessKey,
--         Name,
--         Calendar,
--         Country,
--         Region,
--         Language,
--         InsertedDate,
--         ModifiedDate
--     FROM {{ ref('Stg_Division') }}
-- ),

-- default_row as (
--     select
--         -1 as   {{ this.name }}Id,
--         '-1' as {{ this.name }}ScdId,
--          '-1' as BusinessKey,
--         'Unknown' as DivisionCode,
--         'Unknown' as Name,
--         'Unknown' as Calendar,
--         'Unknown' as Country,
--         'Unknown' as Region,
--         'Unknown' as Language,
--         cast(getdate() as datetime2(0)) as InsertedDate,
--         cast(getdate() as datetime2(0)) as ModifiedDate,
--         cast('1900-01-01' as date) as EffDate,
--         cast('2999-12-31' as date) as EndDate,
--         'Y' as CurrentFlag
--     {% if is_incremental() %}
--     where not exists (select 1 from {{ this }} where {{ this.name }}Id = '-1')
--     {% endif %}
-- ),

-- transformed AS (
--     SELECT 
--         DivisionCode,
--         BusinessKey,
--         Name,
--         Calendar,
--         Country,
--         Region,
--         Language,
--         cast(InsertedDate as datetime2(0)) as InsertedDate,
--         cast(ModifiedDate as datetime2(0)) as ModifiedDate,
--         cast(null as date) as EffDate,
--         cast(null as date) as EndDate,
--         cast(null as {{ dbt.type_string() }}) as CurrentFlag
--     FROM untransformed
-- ),

-- staging_quality AS (
--     SELECT *
--     FROM transformed
-- ),

-- {{scd_engine('staging_quality', model_definition)}}
-- UNION ALL
-- select * from default_row
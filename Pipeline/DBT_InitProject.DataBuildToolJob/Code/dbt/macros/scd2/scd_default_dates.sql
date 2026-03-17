{% macro scd_default_effective_date( ) -%} 
cast('1900-01-01' as date)
{%- endmacro %}

{% macro scd_default_end_date( ) -%} 
cast('2100-12-31' as date)
{%- endmacro %}